const std = @import("std");
const testing = std.testing;
const DecodedInstruction = @import("Instruction.zig").DecodedInstruction;
const InstType = @import("Instruction.zig").InstructionType;
const ExecuteError = @import("Executer.zig").ExecuteError;
const execute = @import("Executer.zig").execute;
const Chip8 = @import("Chip8.zig").Chip8;

test "Executer ???? Unknown – returns error" {
    var emptyChip = Chip8.init();
    emptyChip.register[0] = 100;
    const instr = DecodedInstruction.init(InstType.Unknown, 0xFFFF);
    try testing.expectError(ExecuteError.UnknownInstruction, execute(&emptyChip, instr));
}

test "Executer ANNN SetIndexRegister – sets I to NNN" {
    var emptyChip = Chip8.init();
    const instr = DecodedInstruction.init(InstType.SetIndexReg, 0xABCD);
    try execute(&emptyChip, instr);
    try testing.expectEqual(0xBCD, emptyChip.index_register);
}

test "Executer 7XNN AddVx – happy path" {
    var emptyChip = Chip8.init();
    emptyChip.register[0] = 100;
    const instr = DecodedInstruction.init(InstType.AddVx, 0x700C);
    try execute(&emptyChip, instr);
    try testing.expectEqual(112, emptyChip.register[0]);
}

test "Executer 7XNN AddVx – overflow wraps" {
    var emptyChip = Chip8.init();
    emptyChip.register[0] = 250;
    const instr = DecodedInstruction.init(InstType.AddVx, 0x700C);
    try execute(&emptyChip, instr);
    try testing.expectEqual(6, emptyChip.register[0]);
}

test "Executer 6XNN SetVx – happy path" {
    var emptyChip = Chip8.init();
    const instr = DecodedInstruction.init(InstType.SetVx, 0x600C);
    try execute(&emptyChip, instr);
    try testing.expectEqual(12, emptyChip.register[0]);
}

test "Executer 2NNN Call – happy path" {
    var chip = Chip8.init();
    const call_instr = DecodedInstruction.init(InstType.Call, 0x2310);
    const exp_stack_entry = chip.program_counter;
    try execute(&chip, call_instr);
    try testing.expectEqual(1, chip.stackpointer);
    try testing.expectEqual(0x310, chip.program_counter);
    try testing.expectEqual(exp_stack_entry, chip.stack[0]);
}

test "Executer 2NNN Call – error NNN out of bounds (high)" {
    var chip = Chip8.init();
    const instr = DecodedInstruction.init(InstType.Call, 0xF000);
    try testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}

test "Executer 2NNN Call – error NNN out of bounds (low)" {
    var chip = Chip8.init();
    const instr = DecodedInstruction.init(InstType.Call, 0x01FF);
    try testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}

test "Executer 2NNN Call – error stack overflow" {
    var chip = Chip8.init();
    for (0..16) |i| {
        chip.stack[i] = @intCast(i);
    }
    chip.stackpointer = 16;
    const instr = DecodedInstruction.init(InstType.Call, 0x2300);
    try testing.expectError(ExecuteError.StackOverflow, execute(&chip, instr));
}

test "Executer 2NNN + 00EE Call/Return – happy path" {
    var chip = Chip8.init();
    const initial_pc = chip.program_counter;

    const call_instr = DecodedInstruction.init(InstType.Call, 0x2300);
    try execute(&chip, call_instr);
    try testing.expectEqual(1, chip.stackpointer);
    try testing.expectEqual(0x300, chip.program_counter);
    try testing.expectEqual(initial_pc, chip.stack[0]);

    const return_instr = DecodedInstruction.init(InstType.Return, 0x00EE);
    try execute(&chip, return_instr);
    try testing.expectEqual(0, chip.stackpointer);
    try testing.expectEqual(initial_pc, chip.program_counter);
}

test "Executer 1NNN Jump – happy path" {
    var chip = Chip8.init();
    const instr = DecodedInstruction.init(InstType.Jump, 0x1300);
    try execute(&chip, instr);
    try std.testing.expectEqual(0x300, chip.program_counter);
}

test "Executer 1NNN Jump – error NNN out of bounds (high)" {
    var chip = Chip8.init();
    const instr = DecodedInstruction.init(InstType.Jump, 0xF000);
    try std.testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}

test "Executer 1NNN Jump – error NNN out of bounds (low)" {
    var chip = Chip8.init();
    const instr = DecodedInstruction.init(InstType.Jump, 0x01FF);
    try std.testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}
