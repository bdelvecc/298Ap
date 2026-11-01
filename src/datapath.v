module datapath (
  input  wire [7:0] instr,
  input wire [3:0] alu_op,
  input wire acc_use,  //Accumulator used
  input wire reg_use,  //Register used
  input wire out_use,  //Output on
  input wire imm_use,  //Immediate used
  input wire imm_signed, //Immediate signed
  input wire pc_load     //PC changed
);

  always @(posedge clk) begin
      if(instr[7] == 1'b0) begin
        if()
