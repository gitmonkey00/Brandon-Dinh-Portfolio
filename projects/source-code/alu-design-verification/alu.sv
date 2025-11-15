// ================================================
// ALU Module - Arithmetic Logic Unit
// ================================================
// Supports: ADD, SUB, AND, OR, XOR, SLL, SRL, SLT

module alu #(
  parameter WIDTH = 32
)(
  input  logic [WIDTH-1:0] a,
  input  logic [WIDTH-1:0] b,
  input  logic [2:0]       alu_op,
  output logic [WIDTH-1:0] result,
  output logic             zero
);

  // ALU operation encoding
  typedef enum logic [2:0] {
    ALU_ADD  = 3'b000,
    ALU_SUB  = 3'b001,
    ALU_AND  = 3'b010,
    ALU_OR   = 3'b011,
    ALU_XOR  = 3'b100,
    ALU_SLL  = 3'b101,
    ALU_SRL  = 3'b110,
    ALU_SLT  = 3'b111
  } alu_operation_t;

  always_comb begin
    case (alu_op)
      ALU_ADD:  result = a + b;
      ALU_SUB:  result = a - b;
      ALU_AND:  result = a & b;
      ALU_OR:   result = a | b;
      ALU_XOR:  result = a ^ b;
      ALU_SLL:  result = a << b[4:0];
      ALU_SRL:  result = a >> b[4:0];
      ALU_SLT:  result = ($signed(a) < $signed(b)) ? 1 : 0;
      default:  result = '0;
    endcase
  end

  assign zero = (result == '0);

endmodule