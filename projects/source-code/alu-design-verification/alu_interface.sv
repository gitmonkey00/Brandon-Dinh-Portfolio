// ================================================
// ALU Interface - Verification Interface
// ================================================

interface alu_if #(
  parameter WIDTH = 32
)(
  input logic clk
);

  // Signals
  logic [WIDTH-1:0] a;
  logic [WIDTH-1:0] b;
  logic [2:0]       alu_op;
  logic [WIDTH-1:0] result;
  logic             zero;

  // Clocking block for testbench
  clocking tb_cb @(posedge clk);
    output a;
    output b;
    output alu_op;
    input  result;
    input  zero;
  endclocking

  // Clocking block for monitor
  clocking mon_cb @(posedge clk);
    input a;
    input b;
    input alu_op;
    input result;
    input zero;
  endclocking

  // Modport for testbench
  modport TB (
    clocking tb_cb,
    output a, b, alu_op,
    input  result, zero
  );

  // Modport for monitor
  modport MONITOR (
    clocking mon_cb,
    input a, b, alu_op, result, zero
  );

  // Modport for DUT
  modport DUT (
    input  a, b, alu_op,
    output result, zero
  );

  // Assertions
  property p_zero_flag;
    @(posedge clk) (result == '0) |-> zero;
  endproperty

  assert property (p_zero_flag)
    else $error("Zero flag mismatch: result=%h, zero=%b", 
                result, zero);

endinterface