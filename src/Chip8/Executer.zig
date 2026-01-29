const testing = @import("std").testing;
const DecodedInstruction = @import("Instruction.zig").DecodedInstruction;
const InstType = @import("Instruction.zig").InstructionType;
const Chip8 = @import("Chip8.zig").Chip8;

pub fn execute(chip: *Chip8, instruction: DecodedInstruction) !void {
    switch (instruction.instType) {
        InstType.AddVx => return executeAddVx(chip, instruction),
        InstType.SetVx => return executeSetVx(chip, instruction),
        InstType.Call => return executeCall(chip, instruction),
        InstType.Jump => return executeJump(chip, instruction),
        InstType.Return => return executeReturn(chip),
        InstType.ClearScreen => return executeClearScrean(chip),
        else => return ExecuteError.UnknownInstruction,
    }
}

fn executeAddVx(chip: *Chip8, instruction: DecodedInstruction) !void {
    if (instruction.x > 15) {
        return ExecuteError.InvalidRegister;
    }
    chip.register[instruction.x] = chip.register[instruction.x] +% instruction.nn;
}

fn executeSetVx(chip: *Chip8, instruction: DecodedInstruction) !void {
    if (instruction.x > 15) {
        return ExecuteError.InvalidRegister;
    }
    chip.register[instruction.x] = instruction.nn;
}

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

fn executeJump(chip: *Chip8, instruction: DecodedInstruction) !void {
    if (instruction.nnn >= Chip8.ram_size) {
        return ExecuteError.MemoryOutOfBounds;
    }
    if (instruction.nnn < Chip8.program_start) {
        return ExecuteError.MemoryOutOfBounds;
    }
    chip.program_counter = instruction.nnn;
}

fn executeReturn(chip: *Chip8) !void {
    if (chip.stackpointer == 0) {
        return ExecuteError.StackUnderflow;
    }
    chip.stackpointer -= 1;
    chip.program_counter = chip.stack[chip.stackpointer];
    chip.stack[chip.stackpointer] = 0;
}
fn executeClearScrean(chip: *Chip8) !void {
    if (chip.program_counter > Chip8.ram_size - 2) {
        return ExecuteError.MemoryOutOfBounds;
    }
    chip.program_counter += 2;
}
pub const ExecuteError = error{
    InvalidRegister,
    UnknownInstruction,
    StackOverflow,
    StackUnderflow,
    MemoryOutOfBounds,
};
