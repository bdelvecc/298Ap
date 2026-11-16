# CPU tests

The cocotb suite drives the Tiny Tapeout top-level pins, so the same tests can
run against RTL and the gate-level netlist. It covers instruction behavior,
programs, step timing, reset, and a 10,000-step deterministic random program.

## Run the RTL suite

Install Icarus Verilog and the pinned Python dependencies, then run:

```sh
python -m pip install -r requirements.txt
make -B
```

The GitHub Actions test workflow runs this suite alongside the standalone ALU
and register-file testbenches.

## Run the gate-level suite

After hardening, put the generated top-level gate netlist at
`test/gate_level_netlist.v`, then run:

```sh
make -B GATES=yes
```

The Tiny Tapeout `gl_test` workflow supplies that netlist and invokes this same
cocotb suite.
