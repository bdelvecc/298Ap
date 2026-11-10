`default_nettype none
`timescale 1ns/1ps

module control (
  input  wire [7:0] instr,        
  input  wire second,    //instr is latched, ui_in is its second byte
  input  wire acc_zero,               
  input  wire carry,
  output reg [3:0] alu_op,
  output reg [2:0] b_sel,      //ALU operand B source
  output reg acc_use,  //Accumulator used
  output reg reg_use,  //Register used
  output reg out_use,  //Output on
  output reg carry_use, //Carry flag written
  output reg hi_use,    //Multiply high byte written
  output reg imm_signed, //Immediate signed
  output reg two_byte,   //First byte of a two-byte instruction
  output reg pc_hold,    //PC stays put for this step
  output reg pc_load,    //PC changed
  output reg [1:0] pc_src,
  output reg push,
  output reg pop
);

  //ALU and store + out
  localparam ALU_MUL  = 4'b0101;
  localparam ALU_XOR  = 4'b0001;
  localparam ALU_OR   = 4'b0011;
  localparam ALU_LOAD = 4'b0100; // Pass-through B (used for LOAD / LOADI)
  localparam FN_STORE = 4'b0110;
  localparam FN_OUT = 4'b1111;
  localparam ALU_AND  = 4'b0111;
  localparam ALU_ADD  = 4'b1000;
  localparam ALU_SUB  = 4'b1001;
  localparam ALU_SLL  = 4'b1010;
  localparam ALU_SRL  = 4'b1011;

  //No Operand
  localparam FN_LONG  = 4'b1100;

  //Two byte 
  localparam FN_SYS   = 4'b0010;

  //NO OPERAND INSTRUCTIONS
  localparam SYS_RET    = 3'd1;
  localparam SYS_MFHI   = 3'd2;
  localparam SYS_ADDC   = 3'd5;
  localparam SYS_SUBC   = 3'd6;

  //TWO BYTE INTRUCTIONS
  localparam LONG_LDI  = 3'd0;
  localparam LONG_LJ   = 3'd1;
  localparam LONG_LJZ  = 3'd2;
  localparam LONG_LJNZ = 3'd3;
  localparam LONG_LJC  = 3'd4;
  localparam LONG_CALL = 3'd5;
  localparam LONG_IN   = 3'd6;

  //B Select

  //rtype instr
  localparam B_REG     = 3'd0;
  
  //immediate
  localparam B_IMM     = 3'd1;
  
  //second byte for ldi, in
  localparam B_OPERAND = 3'd2;

  //carry for addc subc
  localparam B_CARRY   = 3'd3;
  
  //hi byte for mfhi
  localparam B_HI      = 3'd4;

  //PC from immediate
  localparam PC_IMM     = 2'd0;
  
  //PC from twobyte instr
  localparam PC_OPERAND = 2'd1;
  
  //pc from the stack for RET
  localparam PC_STACK   = 2'd2;


  
always @(*) begin
  alu_op = 4'b0000; 
  acc_use = 1'b0; 
  reg_use = 1'b0; 
  out_use = 1'b0;
  imm_signed = 1'b0; 
  pc_load = 1'b0;
  if(instr[7] == 1'b0) begin
    alu_op = instr[6:3];
    case(instr[6:3])

      //ALU rtypes
      ALU_ADD, ALU_SUB: begin
         acc_use = 1'b1;
        carry_use = 1'b1;
      end
      ALU_XOR, ALU_OR, ALU_AND, ALU_SLL, ALU_SRL, ALU_LOAD: begin
        acc_use = 1'b1;
      end
      ALU_MUL: begin
        acc_use = 1'b1;
        hi_use = 1'b1;
      end
      FN_STORE: begin
        reg_use = 1'b1;
      end
      FN_OUT: begin
        out_use = 1'b1;
      end


      //No operand instruction
      FN_SYS: begin
        case(instr[2:0])
          SYS_RET: begin
            pc_load = 1'b1;
            pc_src = PC_STACK;
            pop = 1'b1;
          end
          SYS_MFHI: begin
            alu_op = ALU_LOAD;
            b_sel = B_HI;
            acc_use = 1'b1;
          end
          SYS_ADDC: begin
            alu_op = ALU_ADD;
            b_sel = B_CARRY;
            acc_use = 1'b1;
            carry_use = 1'b1;
          end
          SYS_SUBC: begin
            alu_op = ALU_SUB;
            b_sel = B_CARRY;
            acc_use = 1'b1;
            carry_use = 1'b1;
          end
          default: begin
            alu_op = 4'b0000;
          end
        endcase
      end

      //Two byte instructions
      FN_LONG: begin
        alu_op = 4'b0000;
        if(instr[2:0] != 3'd7) begin
          if(!second) begin
            two_byte = 1'b1;
            pc_hold = (instr[2:0] == LONG_IN);
          end
          else begin
            pc_src = PC_OPERAND;
            case(instr[2:0])
              LONG_LDI, LONG_IN: begin
                alu_op = ALU_LOAD;
                b_sel = B_OPERAND;
                acc_use = 1'b1;
              end
              LONG_LJ: begin
                pc_load = 1'b1;
              end
              LONG_LJZ: begin
                pc_load = acc_zero;
              end
              LONG_LJNZ: begin
                pc_load = ~acc_zero;
              end
              LONG_LJC: begin
                pc_load = carry;
              end
              LONG_CALL: begin
                pc_load = 1'b1;
                push = 1'b1;
              end
              default: begin
                pc_load = 1'b0;
              end
            endcase
          end
        end
      end
      default: begin 
        alu_op = 4'b0000;
      end
    endcase
  end
  else begin
    case(instr[6:5])
      2'b00: begin
        alu_op = ALU_ADD;
        acc_use = 1'b1;
        b_sel = B_IMM;
        imm_signed = 1'b1;
      end
      2'b01: begin
        alu_op = ALU_LOAD;
        acc_use = 1'b1;
        b_sel = B_IMM;
      end
      2'b10: begin
        pc_load = acc_zero;
      end
      2'b11: begin
        pc_load = 1'b1;
      end
    endcase
  end
end
endmodule

