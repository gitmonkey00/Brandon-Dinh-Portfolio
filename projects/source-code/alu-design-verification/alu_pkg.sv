// ================================================
// ALU Package - Type Definitions and Constants
// ================================================

package alu_pkg;

  // ALU operation codes
  typedef enum logic [2:0] {
    OP_ADD  = 3'b000,  // Addition
    OP_SUB  = 3'b001,  // Subtraction
    OP_AND  = 3'b010,  // Bitwise AND
    OP_OR   = 3'b011,  // Bitwise OR
    OP_XOR  = 3'b100,  // Bitwise XOR
    OP_SLL  = 3'b101,  // Shift Left Logical
    OP_SRL  = 3'b110,  // Shift Right Logical
    OP_SLT  = 3'b111   // Set Less Than
  } alu_opcode_e;

  // ALU configuration parameters
  parameter int DATA_WIDTH = 32;
  parameter int SHAMT_WIDTH = 5;
  
  // Function to convert opcode to string
  function string opcode_to_string(alu_opcode_e op);
    case (op)
      OP_ADD:  return "ADD";
      OP_SUB:  return "SUB";
      OP_AND:  return "AND";
      OP_OR:   return "OR";
      OP_XOR:  return "XOR";
      OP_SLL:  return "SLL";
      OP_SRL:  return "SRL";
      OP_SLT:  return "SLT";
      default: return "UNKNOWN";
    endcase
  endfunction

  // Transaction class for verification
  class alu_transaction;
    rand logic [DATA_WIDTH-1:0] operand_a;
    rand logic [DATA_WIDTH-1:0] operand_b;
    rand alu_opcode_e operation;
    logic [DATA_WIDTH-1:0] result;
    logic zero_flag;

    // Constraints
    constraint valid_operation {
      operation inside {OP_ADD, OP_SUB, OP_AND, 
                       OP_OR, OP_XOR, OP_SLL, 
                       OP_SRL, OP_SLT};
    }

    // Display function
    function void display(string tag = "");
      $display("%s: %s(%0d, %0d) = %0d [zero=%b]",
               tag, opcode_to_string(operation),
               operand_a, operand_b, result, zero_flag);
    endfunction
  endclass

endpackage