`default_nettype none
`timescale 1ns/1ps

module stack (
  input  wire clk,
  input  wire rst_n,
  input  wire push,
  input  wire pop,
  input  wire [5:0] din,
  output wire [5:0] top
);
  reg [5:0] s0, s1, s2, s3;

  assign top = s0;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      s0 <= 6'd0;
      s1 <= 6'd0;
      s2 <= 6'd0;
      s3 <= 6'd0;
    end
    else if(push) begin
      s0 <= din;
      s1 <= s0;
      s2 <= s1;
      s3 <= s2;
    end
    else if(pop) begin
      s0 <= s1;
      s1 <= s2;
      s2 <= s3;
    end
  end
endmodule
