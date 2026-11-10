`default_nettype none

module cpu(
  input wire clk,
  input wire rst_n,
  input wire [7:0] ui_in,
  input wire step,
  output wire [5:0] pc_out,
  output wire [7:0] out_value,
  output wire out_valid
);
  
  wire [3:0] alu_op;
  wire [2:0] b_sel;
  wire [1:0] pc_src;
  wire [5:0] pc_next;
  wire [5:0] stack_top;
  wire acc_use;
  wire acc_zero;
  wire reg_use;
  wire out_use;
  wire carry_use;
  wire carry_flag;
  wire hi_use;
  wire imm_signed;
  wire two_byte;
  wire pc_hold;
  wire pc_load;
  wire push;
  wire pop;
  wire exec;
  reg [2:0] step_sync;
  reg [7:0] ir;
  reg second;
  reg [5:0] jump_loc;
  wire [7:0] instr = second ? ir : ui_in;
  
  //exec is high for one clock after each rising edge of step
  assign exec = step_sync[1] & ~step_sync[2];
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      step_sync <= 3'b000;
      ir <= 8'b0;
      second <= 1'b0;
    end
    else begin
      step_sync <= {step_sync[1:0], step};
      if(exec) begin
        if(second) second <= 1'b0;
        else if(two_byte) begin
          ir <= ui_in;
          second <= 1'b1;
        end
      end
    end
  end

  always @(*) begin
    case(pc_src)
      2'd1:    jump_loc = ui_in[5:0];
      2'd2:    jump_loc = stack_top;
      default: jump_loc = {1'b0, instr[4:0]};
    endcase
 end

  control controlCPU(
    .instr(instr),
    .second(second),
    .acc_zero(acc_zero),
    .carry(carry_flag),
    .alu_op(alu_op),
    .b_sel(b_sel),
    .acc_use(acc_use),  
    .reg_use(reg_use),  
    .out_use(out_use),  
    .carry_use(carry_use),
    .hi_use(hi_use),
    .imm_signed(imm_signed),
    .two_byte(two_byte),
    .pc_hold(pc_hold),
    .pc_load(pc_load),
    .pc_src(pc_src),
    .push(push),
    .pop(pop)
    
  );
  pc pcCPU(
    .clk(clk),
    .rst_n(rst_n),
    .en(exec & ~pc_hold),
    .pc_load(pc_load),
    .jump_loc(jump_loc),
    .PC(pc_out),
    .PC_next(pc_next)
  );
  stack stackCPU(
    .clk(clk),
    .rst_n(rst_n),
    .push(push & exec),
    .pop(pop & exec),
    .din(pc_next),
    .top(stack_top)
   );
  datapath datapathCPU(
    .exec(exec),
    .instr(instr),
    .operand(ui_in),
    .acc_zero(acc_zero),
    .alu_op(alu_op),
    .b_sel(b_sel),
    .acc_use(acc_use & exec),
    .reg_use(reg_use & exec),
    .out_use(out_use & exec),
    .carry_use(carry_use & exec),
    .hi_use(hi_use & exec),
    .imm_signed(imm_signed), 
    .clk(clk),
    .rst_n(rst_n),
    .output_reg(out_value),
    .out_valid(out_valid),
    .carry_flag(carry_flag)
  );

endmodule
  
