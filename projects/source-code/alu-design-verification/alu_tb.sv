// ================================================
// ALU Testbench - Verification Environment
// ================================================

module alu_tb;

  // Parameters
  parameter WIDTH = 32;
  parameter CLK_PERIOD = 10;

  // DUT signals
  logic [WIDTH-1:0] a, b;
  logic [2:0]       alu_op;
  logic [WIDTH-1:0] result;
  logic             zero;

  // Test variables
  int test_count = 0;
  int pass_count = 0;
  int fail_count = 0;

  // Instantiate DUT
  alu #(.WIDTH(WIDTH)) dut (
    .a(a),
    .b(b),
    .alu_op(alu_op),
    .result(result),
    .zero(zero)
  );

  // Test task
  task automatic test_operation(
    input [WIDTH-1:0] in_a,
    input [WIDTH-1:0] in_b,
    input [2:0]       op,
    input [WIDTH-1:0] expected,
    input string      op_name
  );
    a = in_a;
    b = in_b;
    alu_op = op;
    #1;
    test_count++;
    if (result === expected) begin
      $display("[PASS] %s: %0d op %0d = %0d", 
               op_name, in_a, in_b, result);
      pass_count++;
    end else begin
      $display("[FAIL] %s: Expected %0d, Got %0d", 
               op_name, expected, result);
      fail_count++;
    end
  endtask

  initial begin
    $display("\n=== ALU Testbench Started ===");
    
    // Test ADD operation
    test_operation(10, 5, 3'b000, 15, "ADD");
    test_operation(100, 50, 3'b000, 150, "ADD");
    
    // Test SUB operation
    test_operation(10, 5, 3'b001, 5, "SUB");
    test_operation(100, 25, 3'b001, 75, "SUB");
    
    // Test AND operation
    test_operation(32'hF0F0, 32'h0FF0, 3'b010, 32'h0F0, "AND");
    
    // Test OR operation
    test_operation(32'hF000, 32'h0F00, 3'b011, 32'hFF00, "OR");
    
    // Summary
    $display("\n=== Test Summary ===");
    $display("Total: %0d | Pass: %0d | Fail: %0d", 
             test_count, pass_count, fail_count);
    $finish;
  end

endmodule