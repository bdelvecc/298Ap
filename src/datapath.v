`default_nettype none

module datapath (
  input  wire clk,
  input  wire rst_n,
  input  wire [7:0] instr,
  input wire [3:0] alu_op,
  input wire acc_use,  //Accumulator written to 
  input wire reg_use,  //Register written to 
  input wire out_use,  //Output on
  input wire imm_use,  //Immediate used
  input wire imm_signed, //Immediate signed
  output reg [7:0] output_reg,
  output wire acc_zero

);
  wire [7:0] b;
  wire [7:0] acc_data;
  wire [7:0] r_rdata;
  wire [7:0] alu_out;
  wire [7:0] imm_new;
    alu adp (
      .a(acc_data),
      .b(b),
      .alu_op(alu_op),
      .alu_out(alu_out),
      .zero(),
      .carry()
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
  assign b = imm_use ? imm_new : r_rdata;

  always @(posedge clk) begin
    if(!rst_n) begin
      output_reg <= 0;
    end
    else if(out_use) begin
      output_reg <= acc_data;
    end
  end
endmodule
    
    
