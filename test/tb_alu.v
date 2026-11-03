/*
 * Testbench for 8-bit ALU
 * Verifies all operations defined in Proposal.md
 */

`timescale 1ns/1ps
`default_nettype none

module tb_alu;

  reg  [7:0] a;
  reg  [7:0] b;
  reg  [3:0] alu_op;
  wire [7:0] alu_out;
  wire       zero;
  wire       carry;

  integer errors = 0;

  alu dut (
      .a(a),
      .b(b),
      .alu_op(alu_op),
      .alu_out(alu_out),
      .zero(zero),
      .carry(carry)
  );

  task check_result;
    input [7:0] exp_out;
    input       exp_zero;
    input       exp_carry;
    input [8*16:1] test_name;
    begin
      #1;
      if (alu_out !== exp_out || zero !== exp_zero || carry !== exp_carry) begin
        $display("FAIL [%0s]: a=%h b=%h op=%b | out=%h (exp %h) z=%b (exp %b) c=%b (exp %b)",
                 test_name, a, b, alu_op, alu_out, exp_out, zero, exp_zero, carry, exp_carry);
        errors = errors + 1;
      end else begin
        $display("PASS [%0s]: out=%h, z=%b, c=%b", test_name, alu_out, zero, carry);
      end
    end
  endtask

  initial begin
    $display("--- Starting ALU Self-Checking Tests ---");

    // 1. ADD
    a = 8'd20; b = 8'd30; alu_op = 4'b1000;
    check_result(8'd50, 1'b0, 1'b0, "ADD 20+30");

    // ADD with carry overflow (250 + 10 = 260 -> 4 with carry 1)
    a = 8'd250; b = 8'd10; alu_op = 4'b1000;
    check_result(8'd4, 1'b0, 1'b1, "ADD with carry");

    // ADD resulting in zero
    a = 8'd0; b = 8'd0; alu_op = 4'b1000;
    check_result(8'd0, 1'b1, 1'b0, "ADD zero result");

    // 2. SUB
    a = 8'd50; b = 8'd20; alu_op = 4'b1001;
    check_result(8'd30, 1'b0, 1'b0, "SUB 50-20");

    // SUB with zero result
    a = 8'd42; b = 8'd42; alu_op = 4'b1001;
    check_result(8'd0, 1'b1, 1'b0, "SUB 42-42 = 0");

    // SUB underflow (borrow)
    a = 8'd10; b = 8'd20; alu_op = 4'b1001;
    check_result(8'd246, 1'b0, 1'b1, "SUB with borrow");

    // 3. XOR
    a = 8'b1010_1100; b = 8'b1100_1010; alu_op = 4'b0001;
    check_result(8'b0110_0110, 1'b0, 1'b0, "XOR");

    // 4. OR
    a = 8'b1010_0000; b = 8'b0000_1010; alu_op = 4'b0011;
    check_result(8'b1010_1010, 1'b0, 1'b0, "OR");

    // 5. AND
    a = 8'b1111_0000; b = 8'b1010_1010; alu_op = 4'b0111;
    check_result(8'b1010_0000, 1'b0, 1'b0, "AND");

    // 6. LOAD (pass B)
    a = 8'hAA; b = 8'h55; alu_op = 4'b0100;
    check_result(8'h55, 1'b0, 1'b0, "LOAD pass B");

    // 7. SLL
    a = 8'b0000_0011; b = 8'd2; alu_op = 4'b1010;
    check_result(8'b0000_1100, 1'b0, 1'b0, "SLL by 2");

    a = 8'b1000_0000; b = 8'd1; alu_op = 4'b1010;
    check_result(8'b0000_0000, 1'b1, 1'b0, "SLL out to zero");

    // 8. SRL
    a = 8'b1100_0000; b = 8'd2; alu_op = 4'b1011;
    check_result(8'b0011_0000, 1'b0, 1'b0, "SRL by 2");

    // 9. PASS A (OUT)
    a = 8'hBE; b = 8'hEF; alu_op = 4'b1111;
    check_result(8'hBE, 1'b0, 1'b0, "PASS A");

    if (errors == 0) begin
      $display(">>> ALL ALU TESTS PASSED SUCCESSFULLY! <<<");
    end else begin
      $display(">>> ALU TESTS FAILED WITH %0d ERRORS! <<<", errors);
      $fatal(1, "ALU tests failed");
    end

    $finish;
  end

endmodule
