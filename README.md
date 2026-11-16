# 298Ap 8-bit CPU

298Ap is a step-controlled 8-bit accumulator processor for Tiny Tapeout. It has
eight general-purpose registers, a 6-bit program counter, a four-entry return
stack, carry-aware arithmetic, and a multiply instruction. An external host
stores the 64-byte program, drives instructions and data on `ui_in`, and pulses
`uio[6]` to execute one step.

See [the datasheet](docs/info.md) for the pin protocol and
[the ISA proposal](docs/Proposal.md) for instruction encodings.

## Test

With Icarus Verilog installed, run the cocotb suite and standalone ALU and
register-file benches from the repository root:

```sh
python -m pip install -r test/requirements.txt
make -B -C test
make -C test test_units
```

GitHub Actions runs the same RTL tests. Tiny Tapeout's `gl_test` workflow also
uses the top-level cocotb suite against the gate-level netlist.

## Build

The project targets the GF180MCU process. The Tiny Tapeout GDS workflow builds
the layout from the source list in `info.yaml`; the clock constraint is 50 ns
(20 MHz maximum).
