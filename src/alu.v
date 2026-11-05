`default_nettype none
`timescale 1ns/1ps

module alu (
    input  wire [7:0] a,        // Operand A (typically Accumulator)
    input  wire [7:0] b,        // Operand B (Register read data or immediate)
    input  wire [3:0] alu_op,   // ALU opcode (matches ISA R-type function field)
    output reg  [7:0] alu_out,  // ALU result
    output wire       zero,     // Zero flag: 1 if alu_out == 0
    output wire       carry     // Carry / borrow flag for ADD / SUB
);

  // ALU Opcode Definitions matching Proposal.md ISA specification
  localparam ALU_XOR  = 4'b0001;
  localparam ALU_OR   = 4'b0011;
  localparam ALU_LOAD = 4'b0100; // Pass-through B (used for LOAD / LOADI)
  localparam ALU_AND  = 4'b0111;
  localparam ALU_ADD  = 4'b1000;
  localparam ALU_SUB  = 4'b1001;
  localparam ALU_SLL  = 4'b1010;
  localparam ALU_SRL  = 4'b1011;
  localparam ALU_PASS = 4'b1111; // Pass-through A (used for OUT / accumulator pass)

  reg carry_reg;

  always @(*) begin
    carry_reg = 1'b0;
    case (alu_op)
      ALU_ADD: begin
        {carry_reg, alu_out} = {1'b0, a} + {1'b0, b};
      end
      ALU_SUB: begin
        {carry_reg, alu_out} = {1'b0, a} - {1'b0, b};
      end
      ALU_XOR: begin
        alu_out = a ^ b;
      end
      ALU_OR: begin
        alu_out = a | b;
      end
      ALU_AND: begin
        alu_out = a & b;
      end
      ALU_LOAD: begin
        alu_out = b;
      end
      ALU_SLL: begin
        alu_out = a << b[2:0];
      end
      ALU_SRL: begin
        alu_out = a >> b[2:0];
      end
      ALU_PASS: begin
        alu_out = a;
      end
      default: begin
        alu_out = 8'b0;
      end
    endcase
  end

  assign zero  = (alu_out == 8'b0);
  assign carry = carry_reg;

endmodule
