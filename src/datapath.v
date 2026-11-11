`default_nettype none

module datapath (
  input  wire clk,
  input  wire rst_n,
  input wire exec,
  input  wire [7:0] instr,
  input  wire [7:0] operand,   //Second byte of a two-byte instruction
  input wire [3:0] alu_op,
  input wire [2:0] b_sel,
  input wire acc_use,  //Accumulator written to 
  input wire reg_use,  //Register written to 
  input wire out_use,  //Output on
  input wire carry_use, //Carry flag written to
  input wire hi_use,   //Multiply high byte written to
  output reg out_valid,  //Last step was an OUT
  output reg carry_flag,
  input wire imm_signed, //Immediate signed
  output reg [7:0] output_reg,
  output wire acc_zero

);

  localparam B_REG     = 3'd0;
  localparam B_IMM     = 3'd1;
  localparam B_OPERAND = 3'd2;
  localparam B_CARRY   = 3'd3;
  localparam B_HI      = 3'd4;
  
  reg [7:0] b;
  reg  [7:0] hi_reg;
  wire [7:0] acc_data;
  wire [7:0] r_rdata;
  wire [7:0] alu_out;
  wire [7:0] imm_new;
  wire [7:0] alu_hi;
  wire       alu_carry;


  
    alu adp (
      .a(acc_data),
      .b(b),
      .alu_op(alu_op),
      .alu_out(alu_out),
      .alu_hi(alu_hi),
      .zero(),
      .carry(alu_carry)
    );
    
    register_file rdp (
      .clk(clk),
      .rst_n(rst_n),
        .r_addr(instr[2:0]),
        .r_wen(reg_use),
        .r_wdata(acc_data),
        .r_rdata(r_rdata),
        .acc_wen(acc_use),
        .acc_wdata(alu_out),
        .acc_data(acc_data),
        .acc_zero(acc_zero)
    );
  assign imm_new = {{3{imm_signed & instr[4]}}, instr[4:0]}; //check if msb is 1 and if imm can be signed. if so fill the rest with 1
  always @(*) begin
      case(b_sel)
        B_IMM:     b = imm_new;
        B_OPERAND: b = operand;
        B_CARRY:   b = {7'b0, carry_flag};
        B_HI:      b = hi_reg;
        default:   b = r_rdata;
      endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      output_reg <= 0;
      out_valid <= 0;
      carry_flag <= 0;
      hi_reg <= 0;
    end
    else begin
      if(out_use) output_reg <= acc_data;
      if(exec) out_valid <= out_use;
      if(carry_use) carry_flag <= alu_carry;
      if(hi_use) hi_reg <= alu_hi;
    end
  end
endmodule
    
    
