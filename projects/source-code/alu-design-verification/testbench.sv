//===========================
// testbench.sv
//===========================
`timescale 1ns/1ps
import alu_pkg::*;  // uses alu_op_e from design.sv

module testbench;
  // ---- Clock / reset ----
  logic clk = 0; always #5 clk = ~clk;   // 100 MHz
  logic rst_n;

  // ---- DUT I/O ----
  logic         req_valid, req_ready;
  logic [31:0]  a, b, result;
  alu_op_e      op;
  logic         rsp_valid, zero, neg, ovf, carry;

  // ---- DUT instance (design.sv unchanged) ----
  alu dut (
    .clk(clk), .rst_n(rst_n),
    .req_valid(req_valid), .req_ready(req_ready),
    .a(a), .b(b), .op(op),
    .rsp_valid(rsp_valid), .result(result),
    .zero(zero), .neg(neg), .ovf(ovf), .carry(carry)
  );

  // ---- Tiny functional coverage ----
  alu_op_e     cov_op;
  logic [31:0] cov_a, cov_b;
  logic        cov_ovf;

  covergroup cg_ops_sign_ovf;
    option.per_instance = 1;
    cp_op:   coverpoint cov_op  { bins add={ALU_ADD}; bins sub={ALU_SUB};
                                  bins andb={ALU_AND}; bins orb={ALU_OR};
                                  bins xorb={ALU_XOR}; bins slt={ALU_SLT}; }
    cp_sign: coverpoint {cov_a[31], cov_b[31]} {
              bins pp={2'b00}; bins pn={2'b01}; bins np={2'b10}; bins nn={2'b11}; }
    cp_ovf:  coverpoint cov_ovf { bins no={0}; bins yes={1}; }
    x_all:   cross cp_op, cp_sign, cp_ovf;
  endgroup
  cg_ops_sign_ovf cg = new();

  // ---- Simple golden reference model ----
  function automatic void ref_model(
    input  logic [31:0] ia, ib, input alu_op_e iop,
    output logic [31:0] o_res,
    output logic o_zero, o_neg, o_ovf, o_carry
  );
    logic [32:0] add_full = {1'b0,ia} + {1'b0,ib};
    logic [32:0] sub_full = {1'b0,ia} - {1'b0,ib};
    o_res='0; o_ovf=0; o_carry=0;
    unique case (iop)
      ALU_ADD: begin
        o_res   = add_full[31:0];
        o_carry = add_full[32];
        o_ovf   = ((ia[31]==ib[31]) && (o_res[31]!=ia[31]));
      end
      ALU_SUB: begin
        o_res   = sub_full[31:0];
        o_carry = ~sub_full[32]; // not-borrow
        o_ovf   = ((ia[31]!=ib[31]) && (o_res[31]!=ia[31]));
      end
      ALU_AND: o_res = ia & ib;
      ALU_OR : o_res = ia | ib;
      ALU_XOR: o_res = ia ^ ib;
      ALU_SLT: o_res = {{31{1'b0}}, $signed(ia) < $signed(ib)};
      default: o_res = '0;
    endcase
    o_zero = (o_res=='0);
    o_neg  =  o_res[31];
  endfunction

  // ---- Drive + check helper (no SVA, no timing drama) ----
  int unsigned pass_cnt=0, fail_cnt=0;

  task automatic do_op(input logic [31:0] ia, ib, input alu_op_e iop);
    logic [31:0] exp_res; logic exp_zero, exp_neg, exp_ovf, exp_carry;
    // Pulse request for 1 cycle
    @(posedge clk); a<=ia; b<=ib; op<=iop; req_valid<=1'b1;
    @(posedge clk); req_valid<=1'b0;
    // Wait for response pulse (DUT is single-cycle, this is safe/portable)
    wait (rsp_valid == 1'b1);
    // Compare with golden
    ref_model(ia, ib, iop, exp_res, exp_zero, exp_neg, exp_ovf, exp_carry);
    if (result !== exp_res)       begin $error("RES %h vs %h", result, exp_res); fail_cnt++; end
    else if (zero   !== exp_zero) begin $error("ZERO mismatch");               fail_cnt++; end
    else if (neg    !== exp_neg)  begin $error("NEG  mismatch");               fail_cnt++; end
    else if (ovf    !== exp_ovf)  begin $error("OVF  mismatch");               fail_cnt++; end
    else if (carry  !== exp_carry)begin $error("CARRY mismatch");              fail_cnt++; end
    else pass_cnt++;
    // Sample coverage
    cov_a=ia; cov_b=ib; cov_op=iop; cov_ovf=ovf; cg.sample();
  endtask

  // ---- Test sequence ----
  initial begin
    // Reset
    rst_n=0; req_valid=0; a='0; b='0; op=ALU_ADD;
    repeat (5) @(posedge clk); rst_n=1;

    // Directed edge cases
    do_op(32'h7FFF_FFFF, 32'h0000_0001, ALU_ADD); // +ovf
    do_op(32'h8000_0000, 32'h0000_0001, ALU_SUB); // -ovf
    do_op(32'hDEAD_BEEF, 32'hDEAD_BEEF, ALU_XOR); // zero
    do_op(32'hFFFF_FFFE, 32'h0000_0001, ALU_SLT); // signed less
    do_op(32'h0000_0000, 32'hFFFF_FFFF, ALU_AND); // logic

    // Random sweep
    repeat (200) begin
      alu_op_e r; r = alu_op_e'($urandom_range(0,5));
      do_op($urandom, $urandom, r);
    end

    // Summary
    $display("\nAll tests finished. Pass=%0d, Fail=%0d, Coverage=%.1f%%",
             pass_cnt, fail_cnt, cg.get_coverage());
    $finish;
  end
endmodule
