<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

298Ap is an 8-bit processor project with a custom instruction set. The proposed
architecture uses an RP2040 to supply instructions and receive the processor's
output. The instruction format supports register operations and immediate or
jump operations. The ALU and register file with accumulator are implemented;
datapath and top-level processor integration are still in progress.

## How to test

With Icarus Verilog installed, run these commands from the repository root to
simulate the ALU and register file:

```sh
iverilog -g2012 -Wall -s tb_alu -o /tmp/sim_alu src/alu.v test/tb_alu.v
vvp /tmp/sim_alu
iverilog -g2012 -Wall -s tb_regfile -o /tmp/sim_regfile src/register_file.v test/tb_regfile.v
vvp /tmp/sim_regfile
```

The current Tiny Tapeout top-level is still a temporary example and does not
yet execute processor instructions. Full processor testing will be documented
after integration.

## External hardware

An RP2040 is planned to provide instructions and communicate with the processor.
No external hardware is required by the current standalone ALU and register
file simulations.
