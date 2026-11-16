# 298Ap: 8-bit processor

## Purpose

298Ap is an 8-bit accumulator processor controlled by an external host. The
host stores the program, presents instruction and data bytes on `ui_in`, and
issues one step pulse on `uio_in[6]`. The chip returns output data, the program
counter, and an output-valid strobe.

The processor has an accumulator (`ACC`), eight 8-bit registers (`R0`–`R7`), a
carry/borrow flag, a multiply high-byte register (`HI`), a 6-bit program
counter, and a four-entry return stack. Programs are 64 bytes. All jumps and
calls are absolute.

## Pin assignment

| Pin | Direction at chip | Function |
| --- | --- | --- |
| `clk` | Input | Clock, up to 20 MHz |
| `rst_n` | Input | Active-low asynchronous reset |
| `ena` | Input | Unused; may be tied high |
| `ui_in[7:0]` | Input | Instruction byte, two-byte operand, or `IN` data |
| `uo_out[7:0]` | Output | Output register, updated by `OUT` |
| `uio[5:0]` | Output | Program counter |
| `uio[6]` | Input | Step pulse from the host |
| `uio[7]` | Output | `OUT` valid strobe |

`uio_oe` is `8'hBF`; chip outputs are `uio[5:0]` and `uio[7]`, and chip input is
`uio[6]`. The host sets its `uio[6]` connection as an output and reads the
other seven bidirectional pins.

## Execution protocol

After reset, `PC` is zero. For each byte, the host sets `ui_in`, raises
`uio[6]` for at least four clock cycles, then lowers it for at least four
cycles. The CPU synchronizes the step input and executes one phase per rising
edge of the step pulse. Keep `ui_in` unchanged until the pulse has completed.

For a one-byte instruction, the CPU consumes the byte and advances `PC` by
one, unless the instruction changes control flow. For a two-byte instruction,
the first step consumes the opcode and advances `PC` to its operand. The
second step consumes the operand and advances `PC` again or jumps to the
operand address. `IN` holds `PC` on its opcode while it waits for the host's
data byte; its data step advances `PC` once.

`OUT` copies `ACC` to `uo_out` and asserts `uio[7]` for one step. The output
register holds its last value, while the valid strobe goes low on the next
non-`OUT` step. `PC` is exposed on `uio[5:0]` and wraps modulo 64.

## Instruction formats

### R-type

R-type instructions have bit 7 clear. Bits `[6:3]` select the operation and
bits `[2:0]` select a register.

| Mnemonic | Function `[6:3]` | Encoding | Operation |
| --- | --- | --- | --- |
| `XOR Rn` | `0001` | `0x08`–`0x0F` | `ACC = ACC XOR Rn` |
| System | `0010` | `0x10`–`0x17` | See system instructions below |
| `OR Rn` | `0011` | `0x18`–`0x1F` | `ACC = ACC OR Rn` |
| `LOAD Rn` | `0100` | `0x20`–`0x27` | `ACC = Rn` |
| `MUL Rn` | `0101` | `0x28`–`0x2F` | `HI:ACC = ACC * Rn` |
| `STORE Rn` | `0110` | `0x30`–`0x37` | `Rn = ACC` |
| `AND Rn` | `0111` | `0x38`–`0x3F` | `ACC = ACC AND Rn` |
| `ADD Rn` | `1000` | `0x40`–`0x47` | `ACC = ACC + Rn`; set carry |
| `SUB Rn` | `1001` | `0x48`–`0x4F` | `ACC = ACC - Rn`; set borrow |
| `SLL Rn` | `1010` | `0x50`–`0x57` | `ACC = ACC << Rn[2:0]` |
| `SRL Rn` | `1011` | `0x58`–`0x5F` | `ACC = ACC >> Rn[2:0]` |
| Two-byte group | `1100` | `0x60`–`0x67` | See long instructions below |
| `OUT` | `1111` | `0x78`–`0x7F` | Copy `ACC` to output register |

For `OUT`, the register bits are ignored. Any unused encoding is a no-op that
advances `PC` by one.

### I/J-type

I/J-type instructions have bit 7 set. Bits `[6:5]` select the operation and
bits `[4:0]` hold the immediate.

| Mnemonic | Group | Encoding | Operation |
| --- | --- | --- | --- |
| `ADDI imm` | `00` | `0x80`–`0x9F` | Add sign-extended 5-bit immediate to `ACC` |
| `LOADI imm` | `01` | `0xA0`–`0xBF` | Load unsigned 5-bit immediate into `ACC` |
| `JZ addr` | `10` | `0xC0`–`0xDF` | Jump to 0–31 if `ACC` is zero |
| `J addr` | `11` | `0xE0`–`0xFF` | Jump to 0–31 |

`ADDI` does not change the carry flag. One-byte jump addresses are limited to
0–31.

### System instructions

These instructions use R-type function `0010`; the low three bits select the
operation.

| Instruction | Encoding | Operation |
| --- | --- | --- |
| `RET` | `0x11` | Pop a return address into `PC` |
| `MFHI` | `0x12` | Copy `HI` into `ACC` |
| `ADDC` | `0x15` | `ACC = ACC + carry`; update carry |
| `SUBC` | `0x16` | `ACC = ACC - borrow`; update borrow |

The stack holds four return addresses. A fifth nested `CALL` overwrites the
oldest saved address. The stack is cleared by reset.

### Two-byte instructions

The first byte is `0x60`–`0x66`. The next byte is an unsigned immediate or
absolute address in the range 0–63.

| Instruction | Opcode | Operation |
| --- | --- | --- |
| `LDI byte` | `0x60` | Load the next byte into `ACC` |
| `LJ addr` | `0x61` | Jump to the next byte's address |
| `LJZ addr` | `0x62` | Jump if `ACC` is zero |
| `LJNZ addr` | `0x63` | Jump if `ACC` is nonzero |
| `LJC addr` | `0x64` | Jump if carry/borrow is set |
| `CALL addr` | `0x65` | Push the address after the operand, then jump |
| `IN` | `0x66` | Read a host data byte into `ACC` on the second step |

`IN` occupies one program byte; the host-supplied data byte is not fetched
from program memory. Its first step holds `PC`; its data step increments `PC`.

## Arithmetic and flags

All arithmetic is modulo 256. `ADD` sets carry when the unsigned sum exceeds
255. `SUB` sets the flag when it borrows. `ADDC` adds the carry flag to `ACC`,
and `SUBC` subtracts the borrow flag from `ACC`. These four operations update
the flag. All other instructions preserve it. `LJC` branches when the flag is
set, so it can test either an addition carry or a subtraction borrow.

`MUL` produces an unsigned 16-bit product. The low byte is written to `ACC`
and the high byte to `HI`; `MFHI` makes the high byte available through `OUT`.

## Testing

Run `make -B` in `test/` for the cocotb top-level suite. It is also used by the
Tiny Tapeout gate-level test flow. The Python model test runs 10,000 steps on a
fixed-seed random 64-byte program and compares the visible PC, output value,
and `OUT` strobe after every step.
