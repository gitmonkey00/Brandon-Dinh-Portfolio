//===========================
// design.sv  (RTL)
//===========================
package alu_pkg;
  typedef enum logic [2:0] {
    ALU_ADD = 3'd0, ALU_SUB = 3'd1, ALU_AND = 3'd2,
    ALU_OR  = 3'd3, ALU_XOR = 3'd4, ALU_SLT = 3'd5
  } alu_op_e;
endpackage

module alu #(parameter int WIDTH = 32)(
  input  logic             clk,
  input  logic             rst_n,
  // request
  input  logic             req_valid,
  output logic             req_ready,
  input  logic [WIDTH-1:0] a,
  input  logic [WIDTH-1:0] b,
  input  alu_pkg::alu_op_e op,
  // response
  output logic             rsp_valid,
  output logic [WIDTH-1:0] result,
  output logic             zero,
  output logic             neg,
  output logic             ovf,
  output logic             carry
);
  import alu_pkg::*;
  assign req_ready = 1'b1;   // always ready for simplicity

  // Latch request, respond next cycle (1-cycle pipeline)
  logic [WIDTH-1:0] a_q, b_q;
  alu_op_e          op_q;
  logic             taken_d;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_q <= '0; b_q <= '0; op_q <= ALU_ADD;
      taken_d  <= 1'b0;
      rsp_valid<= 1'b0;
    end else begin
      taken_d <= (req_valid && req_ready); // remember taken request
      if (req_valid && req_ready) begin
        a_q <= a; b_q <= b; op_q <= op;
      end
      rsp_valid <= taken_d; // drive response the FOLLOWING cycle
    end
  end

  // Core datapath (combinational on registered inputs)
  logic signed [WIDTH-1:0] a_s, b_s;
  assign a_s = a_q; assign b_s = b_q;

  logic [WIDTH:0] add_full, sub_full;
  assign add_full = {1'b0,a_q} + {1'b0,b_q};
  assign sub_full = {1'b0,a_q} - {1'b0,b_q};

  logic [WIDTH-1:0] result_c;
  logic             ovf_c, carry_c;

  always_comb begin
    result_c = '0; ovf_c = 1'b0; carry_c = 1'b0;
    unique case (op_q)
      ALU_ADD: begin
        result_c = add_full[WIDTH-1:0];
        carry_c  = add_full[WIDTH];
        ovf_c    = (a_q[WIDTH-1]==b_q[WIDTH-1]) && (result_c[WIDTH-1]!=a_q[WIDTH-1]);
      end
      ALU_SUB: begin
        result_c = sub_full[WIDTH-1:0];
        carry_c  = ~sub_full[WIDTH]; // "not borrow" as carry
        ovf_c    = (a_q[WIDTH-1]!=b_q[WIDTH-1]) && (result_c[WIDTH-1]!=a_q[WIDTH-1]);
      end
      ALU_AND: result_c = a_q & b_q;
      ALU_OR : result_c = a_q | b_q;
      ALU_XOR: result_c = a_q ^ b_q;
      ALU_SLT: result_c = {{(WIDTH-1){1'b0}}, (a_s < b_s)};
      default: result_c = '0;
    endcase
  end

  assign result = result_c;
  assign zero   = (result_c == '0);
  assign neg    =  result_c[WIDTH-1];
  assign ovf    = ovf_c;
  assign carry  = carry_c;
endmodule
