const std = @import("std");
const testing = std.testing;
const DecodedInstruction = @import("Instruction.zig").DecodedInstruction;
const InstType = @import("Instruction.zig").InstructionType;
const ExecuteError = @import("Executer.zig").ExecuteError;
const execute = @import("Executer.zig").execute;
const Chip8 = @import("Chip8.zig").Chip8;

test "Executer ???? Unknown – returns error" {
    var chip = Chip8.init(true);
    chip.register[0] = 100;
    const instr = DecodedInstruction.init(InstType.Unknown, 0xFFFF);
    try testing.expectError(ExecuteError.UnknownInstruction, execute(&chip, instr));
}

test "Executer 00E0 Clear the screen" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.ClearScreen, 0x00E0);
    @memset(&chip.vram, [_]u1{1} ** 64);

    const expected_clean_vram: [32][64]u1 = @splat(@splat(0));
    try execute(&chip, instr);
    try testing.expectEqual(expected_clean_vram, chip.vram);
}

test "Executer 2NNN + 00EE Call/Return – happy path" {
    var chip = Chip8.init(true);
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

test "Executer 1NNN Jump – error NNN out of bounds (low)" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.Jump, 0x01FF);
    try std.testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}

test "Executer 1NNN Jump – happy path" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.Jump, 0x1300);
    try execute(&chip, instr);
    try std.testing.expectEqual(0x300, chip.program_counter);
}

test "Executer 1NNN Jump – error NNN out of bounds (high)" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.Jump, 0xF000);
    try std.testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}

test "Executer 2NNN Call – happy path" {
    var chip = Chip8.init(true);
    const call_instr = DecodedInstruction.init(InstType.Call, 0x2310);
    const exp_stack_entry = chip.program_counter;
    try execute(&chip, call_instr);
    try testing.expectEqual(1, chip.stackpointer);
    try testing.expectEqual(0x310, chip.program_counter);
    try testing.expectEqual(exp_stack_entry, chip.stack[0]);
}

test "Executer 2NNN Call – error NNN out of bounds (high)" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.Call, 0xF000);
    try testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}

test "Executer 2NNN Call – error NNN out of bounds (low)" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.Call, 0x01FF);
    try testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}

test "Executer 2NNN Call – error stack overflow" {
    var chip = Chip8.init(true);
    for (0..16) |i| {
        chip.stack[i] = @intCast(i);
    }
    chip.stackpointer = 16;
    const instr = DecodedInstruction.init(InstType.Call, 0x2300);
    try testing.expectError(ExecuteError.StackOverflow, execute(&chip, instr));
}

test "Executer 3XNN Skip if VX==NN" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SkipVxEqNN, 0x3AFF);

    chip.register[instr.x] = 0xFF;
    try testing.expectEqual(0x200, chip.program_counter);

    try execute(&chip, instr);
    try testing.expectEqual(0x202, chip.program_counter);
}

test "Executer 3XNN No Skip not if VX!=NN" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SkipVxEqNN, 0x3AFF);

    chip.register[instr.x] = 0xDD;
    try testing.expectEqual(0x200, chip.program_counter);

    try execute(&chip, instr);
    try testing.expectEqual(0x200, chip.program_counter);
}

test "Executer 3xNN Index out of bound" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SkipVxEqNN, 0x3AFF);

    chip.register[instr.x] = 0xFF;
    chip.program_counter = Chip8.program_space - 1;

    try testing.expectError(ExecuteError.ProgramCounterOutOfBounds, execute(&chip, instr));
}

test "Executer 4XNN No Skip if VX==NN" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SkipVxNqNN, 0x4AFF);

    chip.register[instr.x] = 0xFF;
    try testing.expectEqual(0x200, chip.program_counter);

    try execute(&chip, instr);
    try testing.expectEqual(0x200, chip.program_counter);
}

test "Executer 4XNN Skip not if VX!=NN" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SkipVxNqNN, 0x4AFF);

    chip.register[instr.x] = 0xDD;
    try testing.expectEqual(0x200, chip.program_counter);

    try execute(&chip, instr);
    try testing.expectEqual(0x202, chip.program_counter);
}

test "Executer 4XNN Index out of bound" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SkipVxNqNN, 0x4AFF);

    chip.register[instr.x] = 0xDD;
    chip.program_counter = Chip8.program_space - 1;

    try testing.expectError(ExecuteError.ProgramCounterOutOfBounds, execute(&chip, instr));
}

test "Executer 5XY0 Skip if VX==VY" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SkipVxEqVy, 0x5AFF);

    chip.register[instr.x] = 0xDD;
    chip.register[instr.y] = 0xDD;
    try testing.expectEqual(0x200, chip.program_counter);

    try execute(&chip, instr);
    try testing.expectEqual(0x202, chip.program_counter);
}

test "Executer 5XY0 Skip not if VX!=VY" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SkipVxEqVy, 0x5AFF);

    chip.register[instr.x] = 0xDD;
    chip.register[instr.y] = 0xDF;
    try testing.expectEqual(0x200, chip.program_counter);

    try execute(&chip, instr);
    try testing.expectEqual(0x200, chip.program_counter);
}

test "Executer 5XY0 Index out of bound" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SkipVxNqNN, 0x4AFF);

    chip.register[instr.x] = 0xDD;
    chip.register[instr.y] = 0xDD;
    chip.program_counter = Chip8.program_space - 1;

    try testing.expectError(ExecuteError.ProgramCounterOutOfBounds, execute(&chip, instr));
}

test "Executer 6XNN SetVx – happy path" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SetVx2NN, 0x600C);
    try execute(&chip, instr);
    try testing.expectEqual(12, chip.register[0]);
}

test "Executer 7XNN AddVx – happy path" {
    var chip = Chip8.init(true);
    chip.register[0] = 100;
    const instr = DecodedInstruction.init(InstType.AddNN2Vx, 0x700C);
    try execute(&chip, instr);
    try testing.expectEqual(112, chip.register[0]);
}

test "Executer 7XNN AddVx – overflow wraps" {
    var chip = Chip8.init(true);
    chip.register[0] = 250;
    const instr = DecodedInstruction.init(InstType.AddNN2Vx, 0x700C);
    try execute(&chip, instr);
    try testing.expectEqual(6, chip.register[0]);
}

test "Executer 8XY0 Set Vy to Vx" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SetVy2Vx, 0x8BC0);
    chip.register[instr.x] = 42;
    try execute(&chip, instr);
    try testing.expectEqual(42, chip.register[instr.y]);
}

test "Executor 8XY1 SetVx to Vx OR Vy" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.Or, 0x8BC1);
    chip.register[instr.x] = 0xC; //1100or
    chip.register[instr.y] = 0x3; //0011
    try execute(&chip, instr); //1111
    try testing.expectEqual(0xF, chip.register[instr.x]);
}

test "Executor 8XY2 SetVx to Vx AND Vy" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.And, 0x8BC2);
    chip.register[instr.x] = 0xC; //1100and
    chip.register[instr.y] = 0x3; //0011
    try execute(&chip, instr); //0000
    try testing.expectEqual(0x0, chip.register[instr.x]);
}

test "Executor 8XY SetVx to VX XOR VY" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.Xor, 0x8BC3);
    chip.register[instr.x] = 0xE; //1110xor
    chip.register[instr.y] = 0x7; //0111
    try execute(&chip, instr); //1001
    try testing.expectEqual(0x9, chip.register[instr.x]);
}

test "Executor 8XY4 Add Vy to Vx - No overflow" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.AddVy2Vx, 0xBC4);
    chip.register[instr.x] = 0x3;
    chip.register[instr.y] = 0x4;

    try execute(&chip, instr);
    try testing.expectEqual(0x7, chip.register[instr.x]);
    try testing.expectEqual(0b00, chip.register[0xF]);
}

test "Executor 8XY4 Add Vy to Vx - Overflow" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.AddVy2Vx, 0xBC4);
    chip.register[instr.x] = 255;
    chip.register[instr.y] = 8;

    try execute(&chip, instr);
    try testing.expectEqual(7, chip.register[instr.x]);
    try testing.expectEqual(0b01, chip.register[0xF]);
}

test "Executor 8XY5 Subtract Vy from Vx - No Overflow" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SubVyFromVx, 0xBC4);
    chip.register[instr.x] = 255;
    chip.register[instr.y] = 8;

    try execute(&chip, instr);
    try testing.expectEqual(247, chip.register[instr.x]);
    try testing.expectEqual(0, chip.register[0xF]);
}

test "Executor 8XY5 Subtract Vy from Vx - Overflow" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SubVyFromVx, 0xBC5);
    chip.register[instr.x] = 3;
    chip.register[instr.y] = 6;

    try execute(&chip, instr);
    try testing.expectEqual(253, chip.register[instr.x]);
    try testing.expectEqual(1, chip.register[0xF]);
}

test "Executor 08XY6 Shift right - 0 shifted out - original" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.ShiftRight, 0x8BC6);
    chip.register[instr.y] = 0x02; //In the original vy was put into vx
    chip.register[0xF] = 1; //Set to 1 to prove it will be set to 0
    try execute(&chip, instr);
    try testing.expectEqual(0x01, chip.register[instr.x]);
    try testing.expectEqual(0, chip.register[0xF]);
}

test "Executor 08XY6 Shift right - 1 shifted out - original" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.ShiftRight, 0x8BC6);
    chip.register[instr.y] = 0x01; //In the original vy was put into vx
    try execute(&chip, instr);
    try testing.expectEqual(0x00, chip.register[instr.x]);
    try testing.expectEqual(1, chip.register[0xF]);
}

test "Executor 08XY6 Shift right - 0 shifted out - SUPER-CHIP" {
    var chip = Chip8.init(true);
    chip.original = false;
    const instr = DecodedInstruction.init(InstType.ShiftRight, 0x8BC6);
    chip.register[instr.x] = 0x02; // With the SUPER-CHIP just register x got shifted
    chip.register[0xF] = 1; //Set to 1 to prove it will be set to 0
    try execute(&chip, instr);
    try testing.expectEqual(0x01, chip.register[instr.x]);
    try testing.expectEqual(0, chip.register[0xF]);
}

test " Executor 08XY6 Shift right - 1 shifted out - SUPER-CHIP" {
    var chip = Chip8.init(true);
    chip.original = false;
    const instr = DecodedInstruction.init(InstType.ShiftRight, 0x8BC6);
    chip.register[instr.x] = 0x01; //In the original vy was put into vx
    try execute(&chip, instr);
    try testing.expectEqual(0x00, chip.register[instr.x]);
    try testing.expectEqual(1, chip.register[0xF]);
}

test "Executor 8XY7 Set Vx to  Vy - Vx - No Overflow" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SubVxFromVy, 0xBC7);
    chip.register[instr.x] = 8;
    chip.register[instr.y] = 255;

    try execute(&chip, instr);
    try testing.expectEqual(247, chip.register[instr.x]);
    try testing.expectEqual(0, chip.register[0xF]);
}

test "Executor 8XY7 Set Vx to  Vy - Vx - Overflow" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SubVxFromVy, 0xBC5);
    chip.register[instr.x] = 6;
    chip.register[instr.y] = 3;

    try execute(&chip, instr);
    try testing.expectEqual(253, chip.register[instr.x]);
    try testing.expectEqual(1, chip.register[0xF]);
}
test "Executor 08XYE Shift left - 0 shifted out - original" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.ShiftLeft, 0x8BCE);
    chip.register[instr.y] = 0x40; //In the original vy was put into vx
    chip.register[0xF] = 1; //Set to 1 to prove it will be set to 0
    try execute(&chip, instr);
    try testing.expectEqual(0x80, chip.register[instr.x]);
    try testing.expectEqual(0, chip.register[0xF]);
}

test "Executor 08XYE Shift left - 1 shifted out - original" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.ShiftLeft, 0x8BCE);
    chip.register[instr.y] = 0x80; //In the original vy was put into vx
    try execute(&chip, instr);
    try testing.expectEqual(0x00, chip.register[instr.x]);
    try testing.expectEqual(1, chip.register[0xF]);
}

test "Executor 08XYE Shift left - 0 shifted out - SUPER-CHIP" {
    var chip = Chip8.init(true);
    chip.original = false;
    const instr = DecodedInstruction.init(InstType.ShiftLeft, 0x8BCE);
    chip.register[instr.x] = 0x40; // With the SUPER-CHIP just register x got shifted
    chip.register[0xF] = 1; //Set to 1 to prove it will be set to 0
    try execute(&chip, instr);
    try testing.expectEqual(0x80, chip.register[instr.x]);
    try testing.expectEqual(0, chip.register[0xF]);
}

test "Executor 08XYE Shift left - 1 shifted out - SUPER-CHIP" {
    var chip = Chip8.init(true);
    chip.original = false;
    const instr = DecodedInstruction.init(InstType.ShiftLeft, 0x8BCE);
    chip.register[instr.x] = 0x80; //In the original vy was put into vx
    try execute(&chip, instr);
    try testing.expectEqual(0x00, chip.register[instr.x]);
    try testing.expectEqual(1, chip.register[0xF]);
}

test "Executer 9XY0 Skip if VX=!Vy" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SkipVxNqVy, 0x9BCE);

    chip.register[instr.x] = 0xFF;
    chip.register[instr.y] = 0xEE;
    try testing.expectEqual(0x200, chip.program_counter);

    try execute(&chip, instr);
    try testing.expectEqual(0x202, chip.program_counter);
}

test "Executer 9XY0 No Skip not if VX==Vy" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SkipVxNqVy, 0x9BCE);

    chip.register[instr.x] = 0xFF;
    chip.register[instr.y] = 0xFF;
    try testing.expectEqual(0x200, chip.program_counter);

    try execute(&chip, instr);
    try testing.expectEqual(0x200, chip.program_counter);
}

test "Executer 9XY0 Index out of bound" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SkipVxNqVy, 0x9BCE);

    chip.register[instr.x] = 0xFF;
    chip.register[instr.y] = 0xEE;
    chip.program_counter = Chip8.program_space - 1;

    try testing.expectError(ExecuteError.ProgramCounterOutOfBounds, execute(&chip, instr));
}

test "Executer ANNN SetIndexRegister – sets I to NNN" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.SetIndexReg2NNNN, 0xABCD);
    try execute(&chip, instr);
    try testing.expectEqual(0xBCD, chip.index_register);
}

test "Executer BNNN Jump to adress NNN + V0" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.JumpWithOffset, 0xB800);

    chip.register[0] = 0x80;

    try execute(&chip, instr);

    try testing.expectEqual(0x880, chip.program_counter);
}

test "Executer BNNN Jump with Offset > program size" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.JumpWithOffset, 0xBFFF);
    chip.register[0] = 0xFF;

    try testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}

test "Executer BNNN Jump with Offset < program start" {
    var chip = Chip8.init(true);
    const instr = DecodedInstruction.init(InstType.JumpWithOffset, 0xB100);
    chip.register[0] = 0x00;

    try testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}
test "Executer CXNN – random masked with NN" {
    var chip = Chip8.init(true);

    const instr = DecodedInstruction.init(InstType.Random, 0xC20F); // VX=2, NN=0x0F

    // Führe mehrmals aus, alle Werte müssen <= 0x0F
    for (0..100) |_| {
        try execute(&chip, instr);
        try testing.expect(chip.register[2] <= 0x0F);
    }
}

test "Executer CXNN – random with NN = 0 returns 0" {
    var chip = Chip8.init(true);

    const instr = DecodedInstruction.init(InstType.Random, 0xC200); // VX=2, NN=0

    try execute(&chip, instr);
    try testing.expectEqual(@as(u8, 0), chip.register[2]);
}

test "Executer FX07 – read delay timer into VX" {
    var chip = Chip8.init(true);

    chip.delay_timer = 123;
    const instr = DecodedInstruction.init(InstType.SetVx2DTimer, 0xFA07); // VX=A=10

    try execute(&chip, instr);

    try testing.expectEqual(@as(u8, 123), chip.register[10]);
}

test "Executer FX07 – delay timer 0" {
    var chip = Chip8.init(true);

    chip.delay_timer = 0;
    const instr = DecodedInstruction.init(InstType.SetVx2DTimer, 0xF007); // VX=0

    try execute(&chip, instr);

    try testing.expectEqual(@as(u8, 0), chip.register[0]);
}

test "Executer DXYN Draw – draws sprite, no collision" {
    var chip = Chip8.init(true);

    chip.index_register = 0x300;
    chip.ram[0x300] = 0xF0; // ####....

    // DXYN: X=1, Y=2, N=1
    const instr = DecodedInstruction.init(InstType.Draw, 0xD121);

    chip.register[instr.x] = 10;
    chip.register[instr.y] = 5;
    try execute(&chip, instr);

    try testing.expectEqual(@as(u1, 1), chip.vram[5][10]);
    try testing.expectEqual(@as(u1, 1), chip.vram[5][11]);
    try testing.expectEqual(@as(u1, 1), chip.vram[5][12]);
    try testing.expectEqual(@as(u1, 1), chip.vram[5][13]);

    try testing.expectEqual(@as(u8, 0), chip.register[0xF]);
}

test "Executer DXYN Draw – memory out of bounds" {
    var chip = Chip8.init(true);

    chip.index_register = chip.ram.len - 1; // 4095

    const instr = DecodedInstruction.init(InstType.Draw, 0xD122);

    chip.register[instr.x] = 0;
    chip.register[instr.y] = 0;

    try testing.expectError(
        ExecuteError.MemoryOutOfBounds,
        execute(&chip, instr),
    );
}

test "Executer DXYN Draw – collision sets VF and unsets pixel" {
    var chip = Chip8.init(true);

    chip.index_register = 0x300;
    chip.ram[0x300] = 0x80;

    const instr = DecodedInstruction.init(InstType.Draw, 0xD121);

    chip.register[instr.x] = 0;
    chip.register[instr.y] = 0;

    try execute(&chip, instr);
    try testing.expectEqual(1, chip.vram[0][0]);
    try testing.expectEqual(0, chip.register[0xF]);

    try execute(&chip, instr);
    try testing.expectEqual(0, chip.vram[0][0]);
    try testing.expectEqual(1, chip.register[0xF]);
}

test "Executer DXYN Draw – wraps horizontally" {
    var chip = Chip8.init(true);

    chip.index_register = 0x300;
    chip.ram[0x300] = 0xC0;

    const instr = DecodedInstruction.init(InstType.Draw, 0xD121);
    chip.register[instr.x] = 63;
    chip.register[instr.y] = 10;

    try execute(&chip, instr);

    try testing.expectEqual(@as(u1, 1), chip.vram[10][63]);
    try testing.expectEqual(@as(u1, 1), chip.vram[10][0]);
}

test "Executer DXYN Draw – wraps vertically" {
    var chip = Chip8.init(true);

    chip.index_register = 0x300;
    chip.ram[0x300] = 0xFF;
    chip.ram[0x301] = 0xFF;

    const instr = DecodedInstruction.init(InstType.Draw, 0xD122);
    chip.register[instr.x] = 5;
    chip.register[instr.y] = 31;

    try execute(&chip, instr);

    try testing.expectEqual(@as(u1, 1), chip.vram[31][5]);
    try testing.expectEqual(@as(u1, 1), chip.vram[0][5]);
}

test "Executer DXYN Draw – draws multiple rows correctly" {
    var chip = Chip8.init(true);

    chip.index_register = 0x300;
    chip.ram[0x300] = 0x80;
    chip.ram[0x301] = 0x40;
    chip.ram[0x302] = 0x20;

    const instr = DecodedInstruction.init(InstType.Draw, 0xD013); // X=0, Y=1, N=3
    chip.register[instr.x] = 10;
    chip.register[instr.y] = 5;
    try execute(&chip, instr);

    try testing.expectEqual(@as(u1, 1), chip.vram[5][10]);
    try testing.expectEqual(@as(u1, 1), chip.vram[6][11]);
    try testing.expectEqual(@as(u1, 1), chip.vram[7][12]);
}

test "Executer EX9E Skip if Key Vx is pressed" {
    var chip = Chip8.init(true);
    chip.register[2] = 0xB;
    chip.keys.press(0xB);

    const instr = DecodedInstruction.init(InstType.SkipVxPressed, 0xE29E);

    try execute(&chip, instr);

    try testing.expectEqual(0x202, chip.program_counter);
}

test "Executer EXA1 Skip if Key Vx is not pressed" {
    var chip = Chip8.init(true);
    chip.register[2] = 0xB;

    const instr = DecodedInstruction.init(InstType.SkipVxNotPressed, 0xE2A1);

    try execute(&chip, instr);

    try testing.expectEqual(0x202, chip.program_counter);
}

test "FX0A no key pressed repeats instruction" {
    var chip = Chip8.init(true);
    chip.program_counter = 0x300;

    const instr = DecodedInstruction.init(InstType.Wait4Key, 0xF10A);

    try execute(&chip, instr);

    try testing.expectEqual(@as(u16, 0x2FE), chip.program_counter);
}

test "FX0A key pressed stores key and continues" {
    var chip = Chip8.init(true);
    chip.program_counter = 0x300;

    chip.keys.press(5);

    const instr = DecodedInstruction.init(InstType.Wait4Key, 0xF10A);

    try execute(&chip, instr);

    try testing.expectEqual(@as(u8, 5), chip.register[1]);
    try testing.expectEqual(@as(u16, 0x300), chip.program_counter);
}

test "FX0A multiple keys pressed lowest index stored" {
    var chip = Chip8.init(true);

    chip.keys.press(7);
    chip.keys.press(2);

    const instr = DecodedInstruction.init(InstType.Wait4Key, 0xF30A);

    try execute(&chip, instr);

    try testing.expectEqual(@as(u8, 2), chip.register[3]);
}

test "Executer FX15 delay = vx" {
    var chip = Chip8.init(true);
    chip.register[0xA] = 0x6;
    chip.delay_timer = 0x3;

    const instr = DecodedInstruction.init(InstType.SetDTimer2VX, 0xFA15);
    try execute(&chip, instr);

    try testing.expectEqual(chip.delay_timer, 0x6);
}

test "Executer FX18 buzzer = vx" {
    var chip = Chip8.init(true);
    chip.register[0xA] = 0x6;
    chip.sound_timer = 0x3;

    const instr = DecodedInstruction.init(InstType.SetSTimer2VX, 0xFA18);
    try execute(&chip, instr);

    try testing.expectEqual(chip.sound_timer, 0x6);
}

test "FX1E Add VX to I – no overflow, original" {
    var chip = Chip8.init(true);
    chip.index_register = 100;
    chip.register[0] = 50;

    const instr = DecodedInstruction.init(InstType.AddToIndex, 0xF01E);

    try execute(&chip, instr);

    try testing.expectEqual(150, chip.index_register);
    try testing.expectEqual(0, chip.register[0xF]);
}

test "FX1E Add VX to I – overflow, original" {
    var chip = Chip8.init(true);
    chip.index_register = 0xFFF0;
    chip.register[1] = 0x20;

    const instr = DecodedInstruction.init(InstType.AddToIndex, 0xF11E);

    try execute(&chip, instr);

    // 0xFFF0 + 0x20 = 0x10010 → wraps around 16-bit
    try testing.expectEqual(0x0010, chip.index_register);
    try testing.expectEqual(1, chip.register[0xF]);
}

test "FX1E Add VX to I – no overflow, modern" {
    var chip = Chip8.init(false);
    chip.index_register = 200;
    chip.register[2] = 55;

    const instr = DecodedInstruction.init(InstType.AddToIndex, 0xF21E);

    try execute(&chip, instr);

    try testing.expectEqual(255, chip.index_register);
    try testing.expectEqual(0, chip.register[0xF]); // VF untouched
}

test "FX1E Add VX to I – overflow, modern" {
    var chip = Chip8.init(false);
    chip.index_register = 0xFFFE;
    chip.register[3] = 10;

    const instr = DecodedInstruction.init(InstType.AddToIndex, 0xF31E);

    try execute(&chip, instr);

    try testing.expectEqual(8, chip.index_register); // wraps
    try testing.expectEqual(0, chip.register[0xF]); // VF unchanged
}

test "FX1E Add VX to I – memory out of bounds" {
    var chip = Chip8.init(true);
    chip.index_register = Chip8.ram_size - 1;
    chip.register[0] = 2;

    const instr = DecodedInstruction.init(InstType.AddToIndex, 0xF01E);

    try testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}

test "Executer FX33 – BCD conversion" {
    var chip = Chip8.init(true);

    chip.index_register = 300;

    const instr = DecodedInstruction.init(InstType.DecimalConversion, 0xF533);
    chip.register[instr.x] = 197;

    try execute(&chip, instr);

    try testing.expectEqual(1, chip.ram[300]);
    try testing.expectEqual(9, chip.ram[301]);
    try testing.expectEqual(7, chip.ram[302]);
}

test "Executer FX29 – font address for digit 0" {
    var chip = Chip8.init(true);

    const instr = DecodedInstruction.init(InstType.FontChar, 0xF329);
    chip.register[instr.x] = 0;

    try execute(&chip, instr);

    try testing.expectEqual(Chip8.fontset_start, chip.index_register);
}

test "Executer FX29 – font address for digit A" {
    var chip = Chip8.init(true);

    const instr = DecodedInstruction.init(InstType.FontChar, 0xF129);
    chip.register[instr.x] = 0xA;

    try execute(&chip, instr);

    try testing.expectEqual(Chip8.fontset_start + 10 * 5, chip.index_register);
}

test "Executer FX29 – ignores upper bits of VX" {
    var chip = Chip8.init(true);

    const instr = DecodedInstruction.init(InstType.FontChar, 0xF229);
    chip.register[instr.x] = 0xAB;

    try execute(&chip, instr);

    try testing.expectEqual(Chip8.fontset_start + 11 * 5, chip.index_register);
}

test "Executer FX33 – memory out of bounds" {
    var chip = Chip8.init(true);

    chip.index_register = chip.ram.len - 2; // nur noch 2 Bytes Platz
    chip.register[0] = 123;

    const instr = DecodedInstruction.init(InstType.DecimalConversion, 0xF033);

    try testing.expectError(
        ExecuteError.MemoryOutOfBounds,
        execute(&chip, instr),
    );
}

test "Executer FX55 – store V0..VX into memory (modern, I unchanged)" {
    var chip = Chip8.init(false);

    chip.index_register = 300;

    chip.register[0] = 0x10;
    chip.register[1] = 0x20;
    chip.register[2] = 0x30;
    chip.register[3] = 0x40;

    const instr = DecodedInstruction.init(InstType.StoreReg2Mem, 0xF355);

    try execute(&chip, instr);

    try testing.expectEqual(@as(u8, 0x10), chip.ram[300]);
    try testing.expectEqual(@as(u8, 0x20), chip.ram[301]);
    try testing.expectEqual(@as(u8, 0x30), chip.ram[302]);
    try testing.expectEqual(@as(u8, 0x40), chip.ram[303]);

    try testing.expectEqual(@as(u16, 300), chip.index_register);
}

test "Executer FX55 – store V0..VX and increment I (original)" {
    var chip = Chip8.init(true); // original behavior

    chip.index_register = 400;

    chip.register[0] = 0xA;
    chip.register[1] = 0xB;
    chip.register[2] = 0xC;

    const instr = DecodedInstruction.init(InstType.StoreReg2Mem, 0xF255);

    try execute(&chip, instr);

    try testing.expectEqual(@as(u8, 0xA), chip.ram[400]);
    try testing.expectEqual(@as(u8, 0xB), chip.ram[401]);
    try testing.expectEqual(@as(u8, 0xC), chip.ram[402]);

    try testing.expectEqual(@as(u16, 403), chip.index_register);
}

test "Executer FX55 – X = 0 stores only V0" {
    var chip = Chip8.init(true);

    chip.index_register = 123;
    chip.register[0] = 77;

    const instr = DecodedInstruction.init(InstType.StoreReg2Mem, 0xF055);

    try execute(&chip, instr);

    try testing.expectEqual(@as(u8, 77), chip.ram[123]);
}

test "Executer FX55 – memory out of bounds" {
    var chip = Chip8.init(false);

    chip.index_register = chip.ram.len - 2;

    chip.register[0] = 1;
    chip.register[1] = 2;
    chip.register[2] = 3;

    const instr = DecodedInstruction.init(InstType.StoreReg2Mem, 0xF255);

    try testing.expectError(ExecuteError.MemoryOutOfBounds, execute(&chip, instr));
}

test "Executer FX55 – exactly fits at end of memory" {
    var chip = Chip8.init(false);

    chip.index_register = chip.ram.len - 3;

    chip.register[0] = 9;
    chip.register[1] = 8;
    chip.register[2] = 7;

    const instr = DecodedInstruction.init(InstType.StoreReg2Mem, 0xF255);

    try execute(&chip, instr);

    try testing.expectEqual(@as(u8, 9), chip.ram[chip.ram.len - 3]);
    try testing.expectEqual(@as(u8, 8), chip.ram[chip.ram.len - 2]);
    try testing.expectEqual(@as(u8, 7), chip.ram[chip.ram.len - 1]);
}

test "FX65 – load V0..VX from memory (modern, I unchanged)" {
    var chip = Chip8.init(false); // modern behavior

    chip.index_register = 500;

    chip.ram[500] = 11;
    chip.ram[501] = 22;
    chip.ram[502] = 33;
    chip.ram[503] = 44;

    // X = 3 → lädt V0..V3
    const instr = DecodedInstruction.init(InstType.StoreMem2Reg, 0xF365);

    try execute(&chip, instr);

    try testing.expectEqual(@as(u8, 11), chip.register[0]);
    try testing.expectEqual(@as(u8, 22), chip.register[1]);
    try testing.expectEqual(@as(u8, 33), chip.register[2]);
    try testing.expectEqual(@as(u8, 44), chip.register[3]);

    try testing.expectEqual(@as(u16, 500), chip.index_register);
}

test "FX65 – load V0..VX and increment I (original)" {
    var chip = Chip8.init(true); // original behavior

    chip.index_register = 600;

    chip.ram[600] = 5;
    chip.ram[601] = 6;
    chip.ram[602] = 7;

    // X = 2 → lädt V0..V2
    const instr = DecodedInstruction.init(InstType.StoreMem2Reg, 0xF265);

    try execute(&chip, instr);

    try testing.expectEqual(@as(u8, 5), chip.register[0]);
    try testing.expectEqual(@as(u8, 6), chip.register[1]);
    try testing.expectEqual(@as(u8, 7), chip.register[2]);

    try testing.expectEqual(@as(u16, 603), chip.index_register);
}

test "FX65 – X = 0 loads only V0" {
    var chip = Chip8.init(false);

    chip.index_register = 1234;
    chip.ram[1234] = 99;

    const instr = DecodedInstruction.init(InstType.StoreMem2Reg, 0xF065);

    try execute(&chip, instr);

    try testing.expectEqual(@as(u8, 99), chip.register[0]);
}

test "FX65 – memory out of bounds" {
    var chip = Chip8.init(false);

    chip.index_register = chip.ram.len - 2;

    // X = 2 → braucht 3 Bytes
    const instr = DecodedInstruction.init(InstType.StoreMem2Reg, 0xF265);

    try testing.expectError(
        ExecuteError.MemoryOutOfBounds,
        execute(&chip, instr),
    );
}

test "FX65 – exactly fits at end of memory" {
    var chip = Chip8.init(false);

    chip.index_register = chip.ram.len - 3;

    chip.ram[chip.ram.len - 3] = 1;
    chip.ram[chip.ram.len - 2] = 2;
    chip.ram[chip.ram.len - 1] = 3;

    const instr = DecodedInstruction.init(InstType.StoreMem2Reg, 0xF265);

    try execute(&chip, instr);

    try testing.expectEqual(@as(u8, 1), chip.register[0]);
    try testing.expectEqual(@as(u8, 2), chip.register[1]);
    try testing.expectEqual(@as(u8, 3), chip.register[2]);
}
