const Instruction = @import("Instruction.zig");
const DecodedInstruction = Instruction.DecodedInstruction;
const InstType = Instruction.InstructionType;
const std = @import("std");

const high_nibble: u16 = 0xF000;
const low_byte: u16 = 0x00FF;
const low_nibble: u16 = 0x000F;

pub fn decode(opcode: u16) DecodedInstruction {
    std.debug.print(
        "\nOpcode & high_nibble {X}, & low_byte {X}\n ",
        .{ (opcode & high_nibble) >> 8, (opcode & low_byte) },
    );
    switch ((opcode & high_nibble) >> 8) {
        0x00 => switch (opcode & low_byte) {
            // Drawing
            0xE0 => return DecodedInstruction.init(InstType.ClearScreen, opcode),
            0x0E => return DecodedInstruction.init(InstType.Return, opcode),
            else => return DecodedInstruction.init(InstType.Unknown, opcode),
        },
        0x10 => return DecodedInstruction.init(InstType.Jump, opcode),
        0x20 => return DecodedInstruction.init(InstType.Call, opcode),
        0x30 => return DecodedInstruction.init(InstType.SkipVxEqNN, opcode),
        0x40 => return DecodedInstruction.init(InstType.SkipVxNqNN, opcode),
        0x50 => return DecodedInstruction.init(InstType.SkipVxEqVy, opcode),
        0x60 => return DecodedInstruction.init(InstType.SetVx, opcode),
        0x70 => return DecodedInstruction.init(InstType.AddVx, opcode),
        0x80 => switch (opcode & low_nibble) {
            // Logic and arithmetic instructions
            0x0 => return DecodedInstruction.init(InstType.Set, opcode),
            0x1 => return DecodedInstruction.init(InstType.Or, opcode),
            0x2 => return DecodedInstruction.init(InstType.And, opcode),
            0x3 => return DecodedInstruction.init(InstType.Xor, opcode),
            0x4 => return DecodedInstruction.init(InstType.Add, opcode),
            0x5 => return DecodedInstruction.init(InstType.SubXY, opcode),
            0x6 => return DecodedInstruction.init(InstType.ShiftRight, opcode),
            0x7 => return DecodedInstruction.init(InstType.SubYX, opcode),
            0xE => return DecodedInstruction.init(InstType.ShiftLeft, opcode),
            else => return DecodedInstruction.init(InstType.Unknown, opcode),
        },
        0x90 => return DecodedInstruction.init(InstType.SkipVxNqVy, opcode),
        0xA0 => return DecodedInstruction.init(InstType.SetIndexReg, opcode),
        0xB0 => return DecodedInstruction.init(InstType.JumpWithOffset, opcode),
        0xC0 => return DecodedInstruction.init(InstType.Random, opcode),
        0xD0 => return DecodedInstruction.init(InstType.Draw, opcode),
        0xE0 => switch (opcode & low_byte) {
            0x9E => return DecodedInstruction.init(InstType.SkipVxPressed, opcode),
            0xA1 => return DecodedInstruction.init(InstType.SkipVxNotPressed, opcode),
            else => return DecodedInstruction.init(InstType.Unknown, opcode),
        },
        0xF0 => switch (opcode & low_byte) {
            0x07 => return DecodedInstruction.init(InstType.SetVx2DTimer, opcode),
            0x0A => return DecodedInstruction.init(InstType.Wait4Key, opcode),
            0x15 => return DecodedInstruction.init(InstType.SetDTimer2VX, opcode),
            0x18 => return DecodedInstruction.init(InstType.SetSTimer2VX, opcode),
            0x1E => return DecodedInstruction.init(InstType.AddToIndex, opcode),
            0x29 => return DecodedInstruction.init(InstType.FontChar, opcode),
            0x33 => return DecodedInstruction.init(InstType.DecimalConversion, opcode),
            0x55 => return DecodedInstruction.init(InstType.StoreReg2Mem, opcode),
            0x65 => return DecodedInstruction.init(InstType.StoreMem2Reg, opcode),
            else => return DecodedInstruction.init(InstType.Unknown, opcode),
        },
        else => return DecodedInstruction.init(InstType.Unknown, opcode),
    }
}
