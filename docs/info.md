## How it works

298Ap is a step-controlled 8-bit processor with an accumulator, eight 8-bit
registers, an ALU, a 6-bit program counter, and a four-entry return stack. An
external controller stores the 64-byte program and supplies one byte per step.
The processor runs exactly one instruction phase for each rising edge on
`uio_in[6]`; the controller must hold `ui_in` steady through the pulse.

One-byte instructions consume one program byte. Two-byte instructions consume
an opcode and a following operand byte. The program counter points to the
operand after the opcode step, then advances past it or loads the target on the
operand step. `IN` is the exception: its second step supplies data on `ui_in`,
and the program counter advances only after that data step.

The accumulator and register file are reset to zero. Arithmetic uses unsigned
8-bit values. `ADD` sets carry on overflow, while `SUB` sets carry on borrow.
`ADDC` and `SUBC` consume that flag for multi-byte arithmetic. Other
instructions leave the flag unchanged. `MUL` writes its low byte to the
accumulator and its high byte to a separate register read by `MFHI`.

`OUT` copies the accumulator to `uo_out` and sets `uio_out[7]` for one step.
The output value remains held between writes. The program counter is visible on
`uio_out[5:0]` and wraps after address 63. `CALL` saves the address after its
operand; `RET` restores it. The return stack holds four addresses, and a fifth
nested call discards the oldest entry.

The complete instruction encoding and pin assignment are listed in
[Proposal.md](Proposal.md).

## Pins

| Signal | Direction at the chip | Function |
| --- | --- | --- |
| `clk` | Input | Clock, 20 MHz maximum (`CLOCK_PERIOD` is 50 ns) |
| `rst_n` | Input | Active-low asynchronous reset |
| `ui_in[7:0]` | Input | Opcode, instruction operand, or `IN` data |
| `uo_out[7:0]` | Output | Value written by `OUT` |
| `uio_in[6]` | Input | Step pulse |
| `uio_out[5:0]` | Output | Program counter |
| `uio_out[7]` | Output | One-step `OUT` valid strobe |
| `uio[6]` | Input | Step pulse; all other bidirectional pins are outputs |

`uio_oe` is `8'hBF`: bits 0–5 and 7 are chip outputs, and bit 6 is a chip
input. On the host controller, set the matching bidirectional pin 6 to output;
read pins 0–5 and 7. The controller writes all eight `ui_in` pins and reads all
eight `uo_out` pins.

## How to test

The cocotb tests use only top-level pins and run against both RTL and the
gate-level netlist. With Icarus Verilog installed, run from `test/`:

```sh
python -m pip install -r requirements.txt
make -B
```

The suite covers reset and idle behavior, all ALU operations, multiply and
`MFHI`, immediate widths, long branches, carry and 16-bit arithmetic, nested
calls, `IN`, repeated `OUT` strobes, program-counter wraparound, unused
opcodes, Fibonacci at four step widths, and 10,000 deterministic random steps
checked against a Python instruction-set model. The GitHub test workflow also
runs the ALU and register-file unit testbenches.

## External hardware

The chip expects a host with eight digital outputs for `ui_in`, one digital
output for the step pulse, and digital inputs for `uo_out`, the six program
counter bits, and `out_valid`. The Tiny Tapeout controller SDK supports
programmatic input writes, output reads, and per-pin direction setup for the
bidirectional bus.

On the Tiny Tapeout RP2040 v2 board (TT06–TT08), the board maps `ui_in[0:7]` to
GPIO `9, 10, 11, 12, 17, 18, 19, 20`, `uio[0:7]` to GPIO `21–28`, and
`uo_out[0:7]` to GPIO `5, 6, 7, 8, 13, 14, 15, 16`. For this design, configure
GPIO27 (`uio[6]`) as an output and the other `uio` pins as inputs; the SDK's
`uio_oe_pico` direction mask is `0x40`. All eight `ui_in` lines can be driven
and all eight `uo_out` lines can be sampled. The `uo_out[1:3]` board routes
are multiplexed and connect to the RP2040 when board GPIO1 is high, as it is
outside reset. The mapping is documented in the [RP2040 v2 board source](https://github.com/TinyTapeout/tt-demo-pcb/tree/v2.1.2).

The current ETR demo board uses an RP2350, while older boards use an RP2040.
The chip-level directions are the same, but firmware must use the GPIO mapping
for the board revision in hand. See the [ETR board specification](https://tinytapeout.com/specs/pcb-etr/).
