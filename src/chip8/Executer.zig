const std = @import("std");
const testing = std.testing;
const DecodedInstruction = @import("Instruction.zig").DecodedInstruction;
const InstType = @import("Instruction.zig").InstructionType;
const Chip8 = @import("Chip8.zig").Chip8;

const FONTSET_BYTES_PER_CHAR: u8 = 5;

pub const ExecuteError = error{
    InvalidRegister,
    UnknownInstruction,
    StackOverflow,
    StackUnderflow,
    MemoryOutOfBounds,
    ProgramCounterOutOfBounds,
};

pub fn execute(chip: *Chip8, instruction: DecodedInstruction) !void {
    switch (instruction.inst_type) {
        InstType.ClearScreen => return executeClearScrean(chip),
        InstType.Return => return executeReturn(chip),
        InstType.Jump => return executeJump(chip, instruction),
        InstType.Call => return executeCall(chip, instruction),
        InstType.SkipVxEqNN => return executeSkipVxEqNN(chip, instruction),
        InstType.SkipVxNqNN => return executeSkipVxNqNN(chip, instruction),
        InstType.SkipVxEqVy => return executeSkipVxEqVy(chip, instruction),
        InstType.SetVx2NN => return executeSetVx(chip, instruction),
        InstType.AddNN2Vx => return executeAddVx(chip, instruction),
        InstType.SetVy2Vx => return executeSetVy2Vx(chip, instruction),
        InstType.Or => return executeOr(chip, instruction),
        InstType.And => return executeAnd(chip, instruction),
        InstType.Xor => return executeXor(chip, instruction),
        InstType.AddVy2Vx => return executeAddVy2Vx(chip, instruction),
        InstType.SubVyFromVx => return executeSubtractVyFromVx(chip, instruction),
        InstType.ShiftRight => return executeShiftRight(chip, instruction),
        InstType.SubVxFromVy => return executeSubtractVxFromVy(chip, instruction),
        InstType.ShiftLeft => return executeShiftLeft(chip, instruction),
        InstType.SkipVxNqVy => return executeSkipVxNqVy(chip, instruction),
        InstType.SetIndexReg2NNNN => chip.index_register = instruction.nnn,
        InstType.JumpWithOffset => return executeJumpWithOffset(chip, instruction),
        InstType.Random => return executeRandom(chip, instruction),
        InstType.Draw => return executeDraw(chip, instruction),
        InstType.SkipVxPressed => return executeSkipVxPressed(chip, instruction),
        InstType.SkipVxNotPressed => return executeSkipVxNotPressed(chip, instruction),
        InstType.SetVx2DTimer => chip.register[instruction.x] = chip.delay_timer,
        InstType.Wait4Key => return executeWaitForKey(chip, instruction),
        InstType.SetDTimer2VX => chip.delay_timer = chip.register[instruction.x],
        InstType.SetSTimer2VX => chip.sound_timer = chip.register[instruction.x],
        InstType.AddToIndex => return executeAddToIndex(chip, instruction),
        InstType.FontChar => executeFontCharachter(chip, instruction),
        InstType.DecimalConversion => return executeDezimalConversion(chip, instruction),
        InstType.StoreReg2Mem => return executeStoreReg2Mem(chip, instruction),
        InstType.StoreMem2Reg => return executeStoreMem2Reg(chip, instruction),
        else => return ExecuteError.UnknownInstruction,
    }
}

/// 00E0 Clear the screen
fn executeClearScrean(chip: *Chip8) !void {
    @memset(&chip.vram, [_]u1{0} ** 64);
}

// 00EE Return
fn executeReturn(chip: *Chip8) !void {
    if (chip.stackpointer == 0) {
        return ExecuteError.StackUnderflow;
    }
    chip.stackpointer -= 1;
    chip.program_counter = chip.stack[chip.stackpointer];
    chip.stack[chip.stackpointer] = 0;
}

/// 1NNN Jump to adress NNN
fn executeJump(chip: *Chip8, instruction: DecodedInstruction) !void {
    if (instruction.nnn >= Chip8.ram_size) {
        return ExecuteError.MemoryOutOfBounds;
    }
    if (instruction.nnn < Chip8.program_start) {
        return ExecuteError.MemoryOutOfBounds;
    }
    chip.program_counter = instruction.nnn;
}

///  2NNN Execute subroutine starting at adress NNN
fn executeCall(chip: *Chip8, instruction: DecodedInstruction) !void {
    if (instruction.nnn >= Chip8.ram_size) {
        return ExecuteError.MemoryOutOfBounds;
    }
    if (instruction.nnn < Chip8.program_start) {
        return ExecuteError.MemoryOutOfBounds;
    }
    if (chip.stackpointer >= 16) {
        return ExecuteError.StackOverflow;
    }
    chip.stack[chip.stackpointer] = chip.program_counter;
    chip.stackpointer += 1;
    chip.program_counter = instruction.nnn;
}

/// 3XNN Skip program counter if VX equals NN
fn executeSkipVxEqNN(chip: *Chip8, instruction: DecodedInstruction) !void {
    if (chip.register[instruction.x] == instruction.nn) {
        if (chip.program_counter >= Chip8.program_space - 1) {
            return ExecuteError.ProgramCounterOutOfBounds;
        }
        chip.program_counter += 2;
    }
}

// 4XNN Skip program counter if VX not equals NN
fn executeSkipVxNqNN(chip: *Chip8, instruction: DecodedInstruction) !void {
    if (chip.register[instruction.x] != instruction.nn) {
        if (chip.program_counter >= Chip8.program_space - 1) {
            return ExecuteError.ProgramCounterOutOfBounds;
        }
        chip.program_counter += 2;
    }
}

/// 5XY0 Skip if VX equals VY
fn executeSkipVxEqVy(chip: *Chip8, instruction: DecodedInstruction) !void {
    if (chip.register[instruction.x] == chip.register[instruction.y]) {
        if (chip.program_counter >= Chip8.program_space - 1) {
            return ExecuteError.ProgramCounterOutOfBounds;
        }
        chip.program_counter += 2;
    }
}

/// 6XNN Stope number NN in register VX
fn executeSetVx(chip: *Chip8, instruction: DecodedInstruction) !void {
    if (instruction.x > 15) {
        return ExecuteError.InvalidRegister;
    }
    chip.register[instruction.x] = instruction.nn;
}

/// 7XNN Add the value NN to register VX
fn executeAddVx(chip: *Chip8, instruction: DecodedInstruction) !void {
    if (instruction.x > 15) {
        return ExecuteError.InvalidRegister;
    }
    chip.register[instruction.x] = chip.register[instruction.x] +% instruction.nn;
}

// 8XY0 Set Vy to Vx
fn executeSetVy2Vx(chip: *Chip8, instruction: DecodedInstruction) void {
    chip.register[instruction.y] = chip.register[instruction.x];
}

// 8XY1 Set Vx to Vx OR Vy
fn executeOr(chip: *Chip8, instruction: DecodedInstruction) void {
    chip.register[instruction.x] |= chip.register[instruction.y];
}

// 8XY2 Set Vx to Vx AND Vy
fn executeAnd(chip: *Chip8, instruction: DecodedInstruction) void {
    chip.register[instruction.x] &= chip.register[instruction.y];
}

// 8XY3 Set Vx to Vx Xor Vy
fn executeXor(chip: *Chip8, instruction: DecodedInstruction) void {
    chip.register[instruction.x] ^= chip.register[instruction.y];
}

// 8XY4 Add Vy to Vx
fn executeAddVy2Vx(chip: *Chip8, instruction: DecodedInstruction) void {
    const result = @addWithOverflow(chip.register[instruction.x], chip.register[instruction.y]);

    chip.register[instruction.x] = result[0];
    chip.register[0xF] = result[1];
}

// 8XY5 Subtract Vy from Vx
fn executeSubtractVyFromVx(chip: *Chip8, instruction: DecodedInstruction) void {
    const result = @subWithOverflow(chip.register[instruction.x], chip.register[instruction.y]);

    chip.register[instruction.x] = result[0];
    chip.register[0xF] = result[1];
}

// 8XY6 Shift Right
fn executeShiftRight(chip: *Chip8, instruction: DecodedInstruction) void {
    if (chip.original) {
        chip.register[instruction.x] = chip.register[instruction.y];
    }

    const overflow = chip.register[instruction.x] & 0x01;
    chip.register[instruction.x] >>= 1;
    chip.register[0xF] = overflow;
}

// 8XY7 Set Vx to Vy - Vx
fn executeSubtractVxFromVy(chip: *Chip8, instruction: DecodedInstruction) void {
    const result = @subWithOverflow(chip.register[instruction.y], chip.register[instruction.x]);

    chip.register[instruction.x] = result[0];
    chip.register[0xF] = result[1];
}
// 8XYE Shift Left
fn executeShiftLeft(chip: *Chip8, instruction: DecodedInstruction) void {
    if (chip.original) {
        chip.register[instruction.x] = chip.register[instruction.y];
    }

    const overflow = chip.register[instruction.x] & 0x80;
    chip.register[instruction.x] <<= 1;
    chip.register[0xF] = overflow >> 7;
}

/// 9XY0 Skip if Vx != Vy
fn executeSkipVxNqVy(chip: *Chip8, instruction: DecodedInstruction) !void {
    if (chip.register[instruction.x] != chip.register[instruction.y]) {
        if (chip.program_counter >= Chip8.program_space - 1) {
            return ExecuteError.ProgramCounterOutOfBounds;
        }
        chip.program_counter += 2;
    }
}
/// ANNN Store memory adress NNN in register I
fn executeSetIndexRegister(chip: *Chip8, instruction: DecodedInstruction) !void {
    chip.index_register = instruction.nnn;
}

// BNNN Jump to NNN with offset V0
fn executeJumpWithOffset(chip: *Chip8, instruction: DecodedInstruction) !void {
    const target_adress = instruction.nnn + chip.register[0];
    if (target_adress >= Chip8.ram_size) {
        return ExecuteError.MemoryOutOfBounds;
    }
    if (target_adress < Chip8.program_start) {
        return ExecuteError.MemoryOutOfBounds;
    }
    chip.program_counter = target_adress;
}

// CXNN Put Random Number
fn executeRandom(chip: *Chip8, instruction: DecodedInstruction) void {
    var prng: std.Random.DefaultPrng = .init(0);
    const randomer = prng.random();
    chip.register[instruction.x] = randomer.uintAtMost(u8, 0xFF) & instruction.nn;
}

// DXYN Draw at Vx Vy N bytest of data to adress stored in I
fn executeDraw(chip: *Chip8, instruction: DecodedInstruction) !void {
    chip.register[0xF] = 0;

    for (0..instruction.n) |row| {
        const addr = chip.index_register + row;
        if (addr >= chip.ram.len) {
            return ExecuteError.MemoryOutOfBounds;
        }
        const sprite_byte: u8 = chip.ram[chip.index_register + row];
        const y_coordinate = (chip.register[instruction.y] + row) % 32;

        for (0..8) |bit| {
            const x_coordinate = (chip.register[instruction.x] + bit) % 64;

            const shift: u3 = @intCast(7 - bit);
            const pixel: u8 = (sprite_byte >> shift) & 1;
            if (pixel == 1) {
                if (chip.vram[y_coordinate][x_coordinate] == 1) {
                    chip.register[0xF] = 1;
                }
                chip.vram[y_coordinate][x_coordinate] ^= 1;
            }
        }
    }
}

// EX9E Skip if Key is equal Vx
fn executeSkipVxPressed(chip: *Chip8, instruction: DecodedInstruction) void {
    if (chip.keys[chip.register[instruction.x]] == true) {
        chip.program_counter += 2;
    }
}

// EXA1 Skip if Key is equal Vx
fn executeSkipVxNotPressed(chip: *Chip8, instruction: DecodedInstruction) void {
    if (chip.keys[chip.register[instruction.x]] == false) {
        chip.program_counter += 2;
    }
}

//FX0A Wait for key store value in register VX
fn executeWaitForKey(chip: *Chip8, instruction: DecodedInstruction) void {
    for (chip.keys, 0..) |key, index| {
        if (key) {
            chip.register[instruction.x] = @intCast(index);
            return;
        }
    }
    chip.program_counter -= 2;
}

fn executeAddToIndex(chip: *Chip8, instruction: DecodedInstruction) !void {
    const result = @addWithOverflow(chip.index_register, chip.register[instruction.x]);
    if (result[0] >= Chip8.ram_size) {
        return ExecuteError.MemoryOutOfBounds;
    }
    chip.index_register = result[0];
    if (chip.original) {
        chip.register[0xF] = if (result[1] == 1) 1 else 0;
    }
}

// FX29 Save Font into Index Register
fn executeFontCharachter(chip: *Chip8, instruction: DecodedInstruction) void {
    const digit = chip.register[instruction.x] & 0x0F;
    chip.index_register = Chip8.fontset_start + digit * FONTSET_BYTES_PER_CHAR;
}

// FX33 Store BCD of Vx in V[I] following
fn executeDezimalConversion(chip: *Chip8, instruction: DecodedInstruction) !void {
    if (chip.index_register + 2 >= chip.ram.len) {
        return ExecuteError.MemoryOutOfBounds;
    }
    chip.ram[chip.index_register] = chip.register[instruction.x] / 100;
    chip.ram[chip.index_register + 1] = (chip.register[instruction.x] % 100) / 10;
    chip.ram[chip.index_register + 2] = (chip.register[instruction.x] % 10);
}

const print = @import("std").debug.print;

// FX55 Save Reg 0..Vx to ram index_register 0..Vx
fn executeStoreReg2Mem(chip: *Chip8, instruction: DecodedInstruction) !void {
    for (0..instruction.x + 1) |i| {
        if (chip.index_register + i >= Chip8.ram_size) {
            // print("throwing error now", .{});
            return ExecuteError.MemoryOutOfBounds;
        }
        chip.ram[chip.index_register + i] = chip.register[i];
    }
    if (chip.original) {
        chip.index_register = chip.index_register + instruction.x + 1;
    }
}

// FX65 Save Mem index_register 0..Vx to register[0..Vx]
fn executeStoreMem2Reg(chip: *Chip8, instruction: DecodedInstruction) !void {
    for (0..instruction.x + 1) |i| {
        if (chip.index_register + i >= Chip8.ram_size) {
            return ExecuteError.MemoryOutOfBounds;
        }
        chip.register[i] = chip.ram[chip.index_register + i];
    }
    if (chip.original) {
        chip.index_register = chip.index_register + instruction.x + 1;
    }
}
