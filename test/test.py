# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


CLOCK_PERIOD_US = 10
STEP_BIT = 0x40


def value(signal):
    """Read a cocotb logic value using the cocotb 2.x API."""
    return signal.value.to_unsigned()


async def reset(dut):
    dut.clk.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    cocotb.start_soon(Clock(dut.clk, CLOCK_PERIOD_US, unit="us").start())
    await ClockCycles(dut.clk, 6)
    assert value(dut.uio_out) & 0x3F == 0
    assert value(dut.uo_out) == 0
    assert value(dut.uio_out) & 0x80 == 0
    assert value(dut.uio_oe) == 0xBF
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)


async def step(dut, byte, high_cycles=4, low_cycles=4):
    """Present one byte and issue one synchronized step pulse."""
    dut.ui_in.value = byte & 0xFF
    dut.uio_in.value = STEP_BIT
    await ClockCycles(dut.clk, high_cycles)
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, low_cycles)


async def instruction(dut, opcode, operand=None, high_cycles=4, low_cycles=4):
    await step(dut, opcode, high_cycles, low_cycles)
    if operand is not None:
        await step(dut, operand, high_cycles, low_cycles)


def pc(dut):
    return value(dut.uio_out) & 0x3F


def out_valid(dut):
    return (value(dut.uio_out) >> 7) & 1


async def program_step(dut, program, high_cycles=4, low_cycles=4):
    address = pc(dut)
    await step(dut, program[address], high_cycles, low_cycles)
    return address


@cocotb.test()
async def test_reset_and_pin_directions(dut):
    await reset(dut)
    assert value(dut.uio_oe) == 0xBF
    assert pc(dut) == 0
    assert value(dut.uo_out) == 0
    assert out_valid(dut) == 0


@cocotb.test()
async def test_no_execution_without_step(dut):
    await reset(dut)
    dut.ui_in.value = 0x60  # LDI prefix; it must not be latched without step.
    await ClockCycles(dut.clk, 20)
    assert pc(dut) == 0
    assert value(dut.uo_out) == 0
    assert out_valid(dut) == 0
    dut.ui_in.value = 0xFF
    await ClockCycles(dut.clk, 20)
    assert pc(dut) == 0
    assert value(dut.uo_out) == 0


@cocotb.test()
async def test_alu_operations(dut):
    await reset(dut)
    await instruction(dut, 0x60, 0x33)  # LDI 0x33
    await step(dut, 0x31)                # STORE R1
    await instruction(dut, 0x60, 0x0F)

    cases = [
        (0x09, 0x3C),  # XOR R1: 0x0F ^ 0x33
        (0x19, 0x3F),  # OR R1
        (0x39, 0x33),  # AND R1
        (0x41, 0x66),  # ADD R1
        (0x49, 0x33),  # SUB R1
        (0x51, 0x98),  # SLL R1 by R1[2:0] == 3
        (0x59, 0x13),  # SRL R1 by 3
        (0x21, 0x33),  # LOAD R1
    ]
    for opcode, expected in cases:
        await step(dut, opcode)
        await step(dut, 0x78)  # OUT
        assert value(dut.uo_out) == expected
        assert out_valid(dut) == 1
        assert value(dut.uio_oe) == 0xBF


@cocotb.test()
async def test_multiply_and_mfhi(dut):
    await reset(dut)
    await instruction(dut, 0x60, 0xFF)
    await step(dut, 0x31)  # R1 = 0xFF
    await instruction(dut, 0x60, 0xFF)
    await step(dut, 0x29)  # 0xFF * 0xFF = 0xFE01
    await step(dut, 0x78)
    assert value(dut.uo_out) == 0x01
    assert out_valid(dut) == 1
    await step(dut, 0x12)  # MFHI
    await step(dut, 0x78)
    assert value(dut.uo_out) == 0xFE
    assert out_valid(dut) == 1


@cocotb.test()
async def test_immediate_widths_and_signed_addi(dut):
    await reset(dut)
    await step(dut, 0xBF)  # LOADI 31
    await step(dut, 0x78)
    assert value(dut.uo_out) == 31
    await step(dut, 0x8F)  # ADDI +15 -> 46
    await step(dut, 0x78)
    assert value(dut.uo_out) == 46
    await step(dut, 0x90)  # ADDI -16 -> 30
    await step(dut, 0x78)
    assert value(dut.uo_out) == 30
    await instruction(dut, 0x60, 0xFF)  # LDI full byte
    await step(dut, 0x78)
    assert value(dut.uo_out) == 0xFF
    await instruction(dut, 0x60, 0x00)
    await step(dut, 0x78)
    assert value(dut.uo_out) == 0


@cocotb.test()
async def test_long_jumps_and_conditions(dut):
    await reset(dut)
    program = [0] * 64
    program[0:2] = [0x61, 40]       # LJ 40
    program[40:43] = [0x60, 0xA5, 0x78]
    program[43:45] = [0x60, 0]     # ACC = 0
    program[45:47] = [0x62, 50]    # LJZ 50
    program[50:54] = [0x60, 0x5A, 0x63, 55]  # LDI; LJNZ 55
    program[55] = 0x78

    assert await program_step(dut, program) == 0
    assert pc(dut) == 1
    assert await program_step(dut, program) == 1
    assert pc(dut) == 40
    await program_step(dut, program)  # LDI opcode
    await program_step(dut, program)  # LDI operand
    await program_step(dut, program)  # OUT
    assert value(dut.uo_out) == 0xA5
    await program_step(dut, program)  # LDI 0 opcode
    await program_step(dut, program)  # LDI 0 operand
    await program_step(dut, program)  # LJZ opcode
    await program_step(dut, program)  # LJZ target
    assert pc(dut) == 50
    await program_step(dut, program)  # LDI opcode
    await program_step(dut, program)  # LDI operand
    await program_step(dut, program)  # LJNZ opcode
    await program_step(dut, program)  # LJNZ target
    assert pc(dut) == 55
    await program_step(dut, program)  # OUT
    assert value(dut.uo_out) == 0x5A
    assert out_valid(dut) == 1


@cocotb.test()
async def test_carry_and_16_bit_add_subtract(dut):
    await reset(dut)
    program = [0] * 64
    program[0:9] = [0x60, 1, 0x31, 0x60, 0xFF, 0x41, 0x78, 0x64, 50]
    program[50:62] = [
        0x60, 0, 0x15, 0x78,       # high byte: 0 + carry -> 1
        0x60, 0, 0x49, 0x78,       # low byte: 0 - 1 -> 0xFF, borrow
        0x60, 1, 0x16, 0x78,       # high byte: 1 - borrow -> 0
    ]
    for _ in range(9):
        await program_step(dut, program)
    assert pc(dut) == 50  # LJC taken with the ADD carry.
    for _ in range(4):
        await program_step(dut, program)
    assert value(dut.uo_out) == 1
    assert out_valid(dut) == 1
    for _ in range(4):
        await program_step(dut, program)
    assert value(dut.uo_out) == 0xFF
    for _ in range(4):
        await program_step(dut, program)
    assert value(dut.uo_out) == 0
    assert out_valid(dut) == 1


@cocotb.test()
async def test_nested_call_and_return(dut):
    await reset(dut)
    program = [0] * 64
    program[0:4] = [0x65, 10, 0x78, 0x00]  # CALL 10; output after return
    program[10:15] = [0x65, 20, 0x60, 0x42, 0x11]
    program[20:23] = [0x60, 0x2A, 0x11]

    for _ in range(10):
        await program_step(dut, program)
    assert pc(dut) == 2
    await program_step(dut, program)
    assert value(dut.uo_out) == 0x42
    assert out_valid(dut) == 1
    assert pc(dut) == 3


@cocotb.test()
async def test_input_instruction(dut):
    await reset(dut)
    await step(dut, 0x66)  # IN opcode uses the current program address.
    assert pc(dut) == 0
    await step(dut, 0x7E)  # Data byte arrives on the second step.
    assert pc(dut) == 1
    await step(dut, 0x78)
    assert value(dut.uo_out) == 0x7E
    assert out_valid(dut) == 1


@cocotb.test()
async def test_out_valid_repeats_for_same_value(dut):
    await reset(dut)
    await instruction(dut, 0x60, 0xA5)
    for _ in range(2):
        await step(dut, 0x78)
        assert value(dut.uo_out) == 0xA5
        assert out_valid(dut) == 1
    await step(dut, 0x00)
    assert value(dut.uo_out) == 0xA5
    assert out_valid(dut) == 0


@cocotb.test()
async def test_pc_wraparound(dut):
    await reset(dut)
    for expected in range(1, 65):
        await step(dut, 0x00)
        assert pc(dut) == expected & 0x3F
        assert out_valid(dut) == 0


@cocotb.test()
async def test_unused_bytes_are_no_ops(dut):
    await reset(dut)
    await instruction(dut, 0x60, 0x5C)
    await step(dut, 0x78)
    assert value(dut.uo_out) == 0x5C
    unused = list(range(0x00, 0x08)) + [0x10, 0x13, 0x14, 0x17, 0x67]
    unused += list(range(0x68, 0x78))
    for byte in unused:
        old_pc = pc(dut)
        await step(dut, byte)
        assert pc(dut) == (old_pc + 1) & 0x3F
        assert value(dut.uo_out) == 0x5C
        assert out_valid(dut) == 0


@cocotb.test()
async def test_fibonacci_at_four_step_speeds(dut):
    program = [0] * 64
    program[0:14] = [
        0x60, 0x00, 0x31,  # R1 = 0 (previous)
        0x60, 0x01, 0x32,  # R2 = 1 (current)
        0x22, 0x78, 0x33, 0x41, 0x32, 0x23, 0x31, 0xE6,
        # loop at 6: output R2, save current, add previous, rotate, jump
    ]
    expected = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]

    for width in (4, 5, 8, 12):
        await reset(dut)
        outputs = []
        for _ in range(160):
            address = pc(dut)
            await step(dut, program[address], width, width)
            if out_valid(dut):
                outputs.append(value(dut.uo_out))
                if len(outputs) == len(expected):
                    break
        assert outputs == expected


class CpuModel:
    """Small architectural model used to check random top-level programs."""

    def __init__(self):
        self.pc = 0
        self.acc = 0
        self.regs = [0] * 8
        self.carry = 0
        self.hi = 0
        self.output = 0
        self.out_valid = 0
        self.ir = 0
        self.second = False
        self.stack = [0] * 4

    def execute(self, data):
        self.out_valid = 0
        if self.second:
            opcode = self.ir
            subop = opcode & 7
            operand = data & 0xFF
            if subop in (0, 6):  # LDI, IN
                self.acc = operand
            elif subop == 1:     # LJ
                self.pc = operand & 0x3F
            elif subop == 2 and self.acc == 0:  # LJZ
                self.pc = operand & 0x3F
            elif subop == 3 and self.acc != 0:  # LJNZ
                self.pc = operand & 0x3F
            elif subop == 4 and self.carry:  # LJC
                self.pc = operand & 0x3F
            elif subop == 5:     # CALL
                self.stack = [(self.pc + 1) & 0x3F] + self.stack[:3]
                self.pc = operand & 0x3F
            else:
                self.pc = (self.pc + 1) & 0x3F
            self.second = False
            return

        opcode = data & 0xFF
        if opcode & 0x80:
            group = (opcode >> 5) & 3
            imm = opcode & 0x1F
            if group == 0:  # ADDI, signed five-bit immediate
                rhs = imm - 32 if imm & 0x10 else imm
                self.acc = (self.acc + rhs) & 0xFF
            elif group == 1:  # LOADI
                self.acc = imm
            elif group == 2 and self.acc == 0:  # JZ
                self.pc = imm
                return
            elif group == 3:  # J
                self.pc = imm
                return
            self.pc = (self.pc + 1) & 0x3F
            return

        function = (opcode >> 3) & 0xF
        reg = opcode & 7
        rhs = self.regs[reg]
        if function == 0x1:      # XOR
            self.acc ^= rhs
        elif function == 0x3:    # OR
            self.acc |= rhs
        elif function == 0x4:    # LOAD
            self.acc = rhs
        elif function == 0x5:    # MUL
            product = self.acc * rhs
            self.acc = product & 0xFF
            self.hi = (product >> 8) & 0xFF
        elif function == 0x6:    # STORE
            self.regs[reg] = self.acc
        elif function == 0x7:    # AND
            self.acc &= rhs
        elif function == 0x8:    # ADD
            total = self.acc + rhs
            self.acc = total & 0xFF
            self.carry = (total >> 8) & 1
        elif function == 0x9:    # SUB (carry means borrow)
            self.carry = int(self.acc < rhs)
            self.acc = (self.acc - rhs) & 0xFF
        elif function == 0xA:    # SLL
            self.acc = (self.acc << (rhs & 7)) & 0xFF
        elif function == 0xB:    # SRL
            self.acc >>= rhs & 7
        elif function == 0xC:    # two-byte instruction group
            subop = opcode & 7
            if subop <= 6:
                self.ir = opcode
                self.second = True
                if subop == 6:   # IN keeps PC on its opcode until data arrives.
                    return
        elif function == 0x2:    # system instructions
            subop = opcode & 7
            if subop == 1:       # RET
                self.pc = self.stack[0]
                self.stack = self.stack[1:] + [self.stack[3]]
                return
            if subop == 2:       # MFHI
                self.acc = self.hi
            elif subop == 5:     # ADDC
                total = self.acc + self.carry
                self.acc = total & 0xFF
                self.carry = (total >> 8) & 1
            elif subop == 6:     # SUBC
                rhs = self.carry
                self.carry = int(self.acc < rhs)
                self.acc = (self.acc - rhs) & 0xFF
        elif function == 0xF:    # OUT
            self.output = self.acc
            self.out_valid = 1

        self.acc &= 0xFF
        self.pc = (self.pc + 1) & 0x3F


@cocotb.test()
async def test_10000_random_bytes_against_model(dut):
    await reset(dut)
    rng = random.Random(0x298A)
    program = [rng.randrange(256) for _ in range(64)]
    model = CpuModel()

    for cycle in range(10000):
        if model.second and (model.ir & 7) == 6:
            byte = rng.randrange(256)  # IN data comes from the host.
        else:
            byte = program[model.pc]
        model.execute(byte)
        await step(dut, byte)

        observed_status = value(dut.uio_out)
        assert observed_status & 0x3F == model.pc, f"PC mismatch at step {cycle}"
        assert (observed_status >> 7) & 1 == model.out_valid, f"out_valid mismatch at step {cycle}"
        assert value(dut.uo_out) == model.output, f"OUT value mismatch at step {cycle}"
        assert value(dut.uio_oe) == 0xBF
