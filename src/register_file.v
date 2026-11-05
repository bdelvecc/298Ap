`default_nettype none
`timescale 1ns/1ps

module register_file (
    input  wire       clk,
    input  wire       rst_n,

    // General Purpose Register File (R0 - R7)
    input  wire [2:0] r_addr,      // 3-bit register address (000 = R0 to 111 = R7)
    input  wire       r_wen,       // Write enable for selected register R[r_addr]
    input  wire [7:0] r_wdata,     // Data to write to R[r_addr] (typically from ACC)
    output wire [7:0] r_rdata,     // Data read from R[r_addr]

    // Accumulator Register (ACC)
    input  wire       acc_wen,     // Write enable for Accumulator
    input  wire [7:0] acc_wdata,   // Data to write to Accumulator (from ALU or immediate)
    output reg  [7:0] acc_data,    // Current Accumulator value
    output wire       acc_zero     // 1 if Accumulator == 0 (condition flag for JZ)
);

  // 8 registers of 8 bits each
  reg [7:0] registers [0:7];
  integer i;

  // Asynchronous read of register file
  assign r_rdata  = registers[r_addr];

  // Zero flag derived from Accumulator
  assign acc_zero = (acc_data == 8'b0);

  // Synchronous write / asynchronous active-low reset
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      acc_data <= 8'b0;
      for (i = 0; i < 8; i = i + 1) begin
        registers[i] <= 8'b0;
      end
    end else begin
      if (acc_wen) begin
        acc_data <= acc_wdata;
      end
      if (r_wen) begin
        registers[r_addr] <= r_wdata;
      end
    end
  end

endmodule
