const std = @import("std");
const testing = @import("std").testing;
const DecodedInstruction = @import("Instruction.zig").DecodedInstruction;
const InstType = @import("Instruction.zig").InstructionType;
const ExecuteError = @import("Executer.zig").ExecuteError;
const execute = @import("Executer.zig").execute;
const Chip8 = @import("Chip8.zig").Chip8;

test "Executer: unknown instruction" {
    var emptyChip = Chip8.init();
    emptyChip.register[0] = 100;
    const instr = DecodedInstruction{ .instType = InstType.Unknown };
    try testing.expectError(ExecuteError.UnknownInstruction, execute(&emptyChip, instr));
}

// Tests vor AddVx
test "Executer: AddVx happy" {
    var emptyChip = Chip8.init();
    emptyChip.register[0] = 100;
    const instr = DecodedInstruction{ .instType = InstType.AddVx, .x = 0, .nn = 12 };
    try execute(&emptyChip, instr);
    try testing.expectEqual(112, emptyChip.register[0]);
}

test "Executer: AddVx overflow" {
    var emptyChip = Chip8.init();
    emptyChip.register[0] = 250;
    const instr = DecodedInstruction{ .instType = InstType.AddVx, .x = 0, .nn = 12 };
    try execute(&emptyChip, instr);
    try testing.expectEqual(6, emptyChip.register[0]);
}

test "Executer: AddVx InvalidRegisterError" {
    var emptyChip = Chip8.init();
    const instr = DecodedInstruction{ .instType = InstType.AddVx, .x = 20, .nn = 12 };
    try testing.expectError(ExecuteError.InvalidRegister, execute(&emptyChip, instr));
}

// Test for SetVx
test "Executer SetVx happy" {
    var emptyChip = Chip8.init();
    const instr = DecodedInstruction{ .instType = InstType.SetVx, .x = 0, .nn = 12 };
    try execute(&emptyChip, instr);
    try testing.expectEqual(12, emptyChip.register[0]);
}

test "Executer: SetVx InvalidRegisterError" {
    var emptyChip = Chip8.init();
    const instr = DecodedInstruction{ .instType = InstType.SetVx, .x = 20, .nn = 12 };
    try testing.expectError(ExecuteError.InvalidRegister, execute(&emptyChip, instr));
}

test "Executer: Call happy" {
    var emptyChip = Chip8.init();
    const instr = DecodedInstruction{ .instType = InstType.Call, .nnn = 0x210 };
    const exp_stack_entry = emptyChip.program_counter;
    try execute(&emptyChip, instr);
    try testing.expectEqual(1, emptyChip.stackpointer);
    try testing.expectEqual(0x210, emptyChip.program_counter);
    try testing.expectEqual(exp_stack_entry, emptyChip.stack[0]);
}

test "Executer: Call error - NNN too large" {
    var chip = Chip8.init();
    const instr = DecodedInstruction{ .instType = InstType.Call, .nnn = Chip8.ram_size + 1 };
    try testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}

test "Executer: Call error - NNN too small" {
    var chip = Chip8.init();
    const program_start: u16 = 0x200;
    const instr = DecodedInstruction{ .instType = InstType.Call, .nnn = program_start - 1 };
    try testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}

test "Executer: Call error - Stack overflow" {
    var chip = Chip8.init();

    for (0..16) |i| {
        chip.stack[i] = @intCast(i);
    }
    chip.stackpointer = 16;

    const instr = DecodedInstruction{ .instType = InstType.Call, .nnn = 0x300 };
    try testing.expectError(ExecuteError.StackOverflow, execute(&chip, instr));
}
test "Executer: Call Return happy" {
    var chip = Chip8.init();

    const initial_pc = chip.program_counter;
    const call_instr = DecodedInstruction{
        .instType = InstType.Call,
        .nnn = 0x300,
    };
    try execute(&chip, call_instr);
    try testing.expectEqual(1, chip.stackpointer);
    try testing.expectEqual(0x300, chip.program_counter);
    try testing.expectEqual(initial_pc, chip.stack[0]);

    const return_instr = DecodedInstruction{ .instType = InstType.Return };
    try execute(&chip, return_instr);
    try testing.expectEqual(0, chip.stackpointer);
    try testing.expectEqual(initial_pc, chip.program_counter);
}

test "Executer: Jump happy" {
    var chip = Chip8.init();
    const instr = DecodedInstruction{
        .instType = InstType.Jump,
        .nnn = 0x300,
    };

    try execute(&chip, instr);

    try std.testing.expectEqual(0x300, chip.program_counter);
}

test "Executer: Jump error - NNN too large" {
    var chip = Chip8.init();
    const instr = DecodedInstruction{
        .instType = InstType.Jump,
        .nnn = Chip8.ram_size + 1,
    };

    try std.testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}

test "Executer: Jump error - NNN too small" {
    var chip = Chip8.init();
    const instr = DecodedInstruction{
        .instType = InstType.Jump,
        .nnn = Chip8.program_start - 1, // unterhalb Programmbereich 0x200
    };

    try std.testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}
