/*
 * Testbench for 8-bit Register File + Accumulator
 */

`timescale 1ns/1ps
`default_nettype none

module tb_regfile;

  reg        clk;
  reg        rst_n;
  reg  [2:0] r_addr;
  reg        r_wen;
  reg  [7:0] r_wdata;
  wire [7:0] r_rdata;
  reg        acc_wen;
  reg  [7:0] acc_wdata;
  wire [7:0] acc_data;
  wire       acc_zero;

  integer errors = 0;
  integer i;

  register_file dut (
      .clk(clk),
      .rst_n(rst_n),
      .r_addr(r_addr),
      .r_wen(r_wen),
      .r_wdata(r_wdata),
      .r_rdata(r_rdata),
      .acc_wen(acc_wen),
      .acc_wdata(acc_wdata),
      .acc_data(acc_data),
      .acc_zero(acc_zero)
  );

  // Clock generation: 10ns period (100MHz)
  always #5 clk = ~clk;

  initial begin
    $display("--- Starting Register File & Accumulator Tests ---");
    clk = 0;
    rst_n = 1;
    r_addr = 0;
    r_wen = 0;
    r_wdata = 0;
    acc_wen = 0;
    acc_wdata = 0;

    // 1. Reset Test
    #2;
    rst_n = 0;
    #10;
    if (acc_data !== 8'h00 || acc_zero !== 1'b1) begin
      $display("FAIL [Reset]: acc_data=%h (exp 00), acc_zero=%b (exp 1)", acc_data, acc_zero);
      errors = errors + 1;
    end else begin
      $display("PASS [Reset]: ACC is 0 and acc_zero is 1");
    end

    // Verify all registers reset to 0
    for (i = 0; i < 8; i = i + 1) begin
      r_addr = i[2:0];
      #1;
      if (r_rdata !== 8'h00) begin
        $display("FAIL [Reset R%0d]: r_rdata=%h (exp 00)", i, r_rdata);
        errors = errors + 1;
      end
    end
    if (errors == 0) $display("PASS [Reset]: All 8 registers initialized to 0");

    // Release Reset
    @(posedge clk);
    #1 rst_n = 1;

    // 2. Write to each register R0 - R7
    for (i = 0; i < 8; i = i + 1) begin
      @(posedge clk);
      #1;
      r_addr = i[2:0];
      r_wdata = 8'h10 + i[7:0]; // 0x10, 0x11, ... 0x17
      r_wen = 1;
    end

    @(posedge clk);
    #1;
    r_wen = 0;

    // 3. Read back each register R0 - R7 asynchronously
    for (i = 0; i < 8; i = i + 1) begin
      r_addr = i[2:0];
      #2;
      if (r_rdata !== (8'h10 + i[7:0])) begin
        $display("FAIL [Read R%0d]: r_rdata=%h (exp %h)", i, r_rdata, (8'h10 + i[7:0]));
        errors = errors + 1;
      end else begin
        $display("PASS [Read R%0d]: value = %h", i, r_rdata);
      end
    end

    // 4. Test Accumulator Write
    @(posedge clk);
    #1;
    acc_wen = 1;
    acc_wdata = 8'hA5;
    @(posedge clk);
    #1;
    acc_wen = 0;
    if (acc_data !== 8'hA5 || acc_zero !== 1'b0) begin
      $display("FAIL [ACC write A5]: acc_data=%h (exp A5), acc_zero=%b (exp 0)", acc_data, acc_zero);
      errors = errors + 1;
    end else begin
      $display("PASS [ACC write A5]: acc_data = %h, acc_zero = %b", acc_data, acc_zero);
    end

    // 5. Test Accumulator Zero flag
    @(posedge clk);
    #1;
    acc_wen = 1;
    acc_wdata = 8'h00;
    @(posedge clk);
    #1;
    acc_wen = 0;
    if (acc_data !== 8'h00 || acc_zero !== 1'b1) begin
      $display("FAIL [ACC write 00]: acc_data=%h (exp 00), acc_zero=%b (exp 1)", acc_data, acc_zero);
      errors = errors + 1;
    end else begin
      $display("PASS [ACC write 00]: acc_data = %h, acc_zero = %b", acc_data, acc_zero);
    end

    // 6. Test Simultaneous Write to R3 and ACC
    @(posedge clk);
    #1;
    r_addr = 3'd3;
    r_wdata = 8'h77;
    r_wen = 1;
    acc_wdata = 8'h99;
    acc_wen = 1;
    @(posedge clk);
    #1;
    r_wen = 0;
    acc_wen = 0;

    r_addr = 3'd3;
    #2;
    if (r_rdata !== 8'h77 || acc_data !== 8'h99) begin
      $display("FAIL [Simultaneous write]: R3=%h (exp 77), ACC=%h (exp 99)", r_rdata, acc_data);
      errors = errors + 1;
    end else begin
      $display("PASS [Simultaneous write]: R3 = %h, ACC = %h", r_rdata, acc_data);
    end

    // 7. Verify other registers were not affected
    r_addr = 3'd2;
    #2;
    if (r_rdata !== 8'h12) begin
      $display("FAIL [Isolation check]: R2=%h (exp 12)", r_rdata);
      errors = errors + 1;
    end else begin
      $display("PASS [Isolation check]: R2 is still %h", r_rdata);
    end

    if (errors == 0) begin
      $display(">>> ALL REGISTER FILE TESTS PASSED SUCCESSFULLY! <<<");
    end else begin
      $display(">>> REGISTER FILE TESTS FAILED WITH %0d ERRORS! <<<", errors);
      $fatal(1, "Register file tests failed");
    end

    $finish;
  end

endmodule
