`default_nettype none
`timescale 1ns/1ps

module pc (
  input wire rst_n,
  input wire clk,
  input wire en,
  input wire pc_load,
  input wire [5:0] jump_loc,
  output reg [5:0] PC,
  output wire [5:0] PC_next
);
  assign PC_next = PC + 6'd1;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) PC <= 6'd0;
    else if (en) begin
      if(pc_load) PC <= jump_loc;
      else PC <= PC_next;
    end
  end
  endmodule
