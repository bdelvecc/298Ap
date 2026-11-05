`default_nettype none

module cpu(
  input  wire clk,
  input  wire rst_n,
  input  wire [7:0] instr,
  output wire [5:0] pc_out,
  output wire [7:0] out_value
);
  
  wire [3:0] alu_op;
  wire acc_use;
  wire acc_zero;
  wire reg_use;
  wire out_use;
  wire imm_use;
  wire imm_signed;
  wire pc_load;

  control controlCPU(
    .instr(instr),        
    .acc_zero(acc_zero),               
    .alu_op(alu_op),
    .acc_use(acc_use),  
    .reg_use(reg_use),  
    .out_use(out_use),  
    .imm_use(imm_use),  
    .imm_signed(imm_signed), 
    .pc_load(pc_load)     
    
  );
  pc pcCPU(
    .clk(clk),
    .rst_n(rst_n),
    .en(1'b1),
    .pc_load(pc_load),
    .jump_loc({1'b0, instr[4:0]}),
    .PC(pc_out)    
  );
  datapath datapathCPU(
    .instr(instr),        
    .acc_zero(acc_zero),               
    .alu_op(alu_op),
    .acc_use(acc_use),  
    .reg_use(reg_use),  
    .out_use(out_use),  
    .imm_use(imm_use),  
    .imm_signed(imm_signed), 
    .clk(clk),
    .rst_n(rst_n),
    .output_reg(out_value)
  );

endmodule
  
