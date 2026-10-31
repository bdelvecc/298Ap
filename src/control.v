module control (
  input  wire [7:0] instr,        
  input  wire acc_zero,               
  output reg [3:0] alu_op,
  output reg acc_use,  //Accumulator used
  output reg reg_use,  //Register used
  output reg out_use,  //Output on
  output reg imm_use,  //Immediate used
  output reg imm_signed, //Immediate signed
  output reg pc_load     //PC changed
);
  
  localparam ALU_XOR  = 4'b0001;
  localparam ALU_OR   = 4'b0011;
  localparam ALU_LOAD = 4'b0100; // Pass-through B (used for LOAD / LOADI)
  localparam ALU_STORE = 4'b0110;
  localparam ALU_OUT = 4'b1111;
  localparam ALU_AND  = 4'b0111;
  localparam ALU_ADD  = 4'b1000;
  localparam ALU_SUB  = 4'b1001;
  localparam ALU_SLL  = 4'b1010;
  localparam ALU_SRL  = 4'b1011;
  localparam ALU_PASS = 4'b1111; // Pass-through A (used for OUT / accumulator pass)

always @(*) begin
  alu_op = 4'b0000; 
  acc_use = 1'b0; 
  reg_use = 1'b0; 
  out_use = 1'b0;
  imm_use = 1'b0; 
  imm_signed = 1'b0; 
  pc_load = 1'b0;
  if(instr[7] = 1'b0) begin
    alu_op = instr[6:3];
    case(instr[6:3])
      ALU_ADD, ALU_SUB, ALU_XOR, ALU_OR, ALU_AND, ALU_SLL, ALU_SRL, ALU_LOAD: begin
        acc_use = 1'b1;
      end
      ALU_STORE: begin
        reg_use = 1'b1;
      end
      ALU_OUT: begin
        out_use = 1'b1;
      end
  else begin
    case(instr[6:5])
      2'b00: begin
        alu_op = ALU_ADD;
        acc_use = 1'b1;
        imm_use = 1'b1;
      end
      2'b01: begin
        alu_op = ALU_LOAD;
        acc_use = 1'b1;
        imm_use = 1'b1;
      end
      2'b10: begin
        pc_load = 1'b1;
        acc_zero = 1'b1;
      end
  end
      2'b11: begin
        pc_load = 1'b1;
        pc_load = 1'b1;
      end
