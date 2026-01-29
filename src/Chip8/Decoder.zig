const Instruction = @import("Instruction.zig");
const DecodedInstruction = Instruction.DecodedInstruction;
const InstType = Instruction.InstructionType;
const std = @import("std");

const high_nibble: u16 = 0xF000;

pub fn decode(opcode: u16) DecodedInstruction {
    switch (opcode & high_nibble) {
        @intFromEnum(InstType.AddVx) => return decodeAddVx(opcode),
        @intFromEnum(InstType.SetVx) => return decodeSetVx(opcode),
        @intFromEnum(InstType.Call) => return decodeCall(opcode),
        @intFromEnum(InstType.Jump) => return decodeJump(opcode),
        0x00 => switch (opcode) {
            0x00EE => return DecodedInstruction{ .instType = InstType.Return },
            0x00E0 => return DecodedInstruction{ .instType = InstType.ClearScreen }, //ClearScrean does not use anymore data
            else => return DecodedInstruction{ .instType = InstType.Unknown },
        },
        else => return DecodedInstruction{ .instType = InstType.Unknown },
    }
}

fn decodeJump(opcode: u16) DecodedInstruction {
    const nnn = (opcode & 0x0FFF);
    return DecodedInstruction{
        .instType = InstType.Jump,
        .nnn = @intCast(nnn),
    };
}

fn decodeCall(opcode: u16) DecodedInstruction {
    const nnn = (opcode & 0x0FFF);
    return DecodedInstruction{
        .instType = InstType.Call,
        .nnn = @intCast(nnn),
    };
}

fn decodeSetVx(opcode: u16) DecodedInstruction {
    const x: u16 = (opcode & 0x0F00) >> 8;
    const nn = opcode & 0x00FF;
    return DecodedInstruction{
        .instType = InstType.SetVx,
        .x = @intCast(x),
        .nn = @intCast(nn),
    };
}

fn decodeAddVx(opcode: u16) DecodedInstruction {
    const x: u16 = (opcode & 0x0F00) >> 8;
    const nn = opcode & 0x00FF;
    return DecodedInstruction{
        .instType = InstType.AddVx,
        .x = @intCast(x),
        .nn = @intCast(nn),
    };
}

test "decode AddVx 7XNN" {
    const opcode: u16 = 0x7B10; // 7B10 → Add 0x10 to V11
    const decoded: DecodedInstruction = decode(opcode);

    try std.testing.expect(decoded.instType == .AddVx);
    try std.testing.expect(decoded.x == 0xB);
    try std.testing.expect(decoded.nn == 0x10);
}

test "decode SetVx 6XNN" {
    const opcode: u16 = 0x6A0F; // 6A0F → Set V10 = 0x0F
    const decoded: DecodedInstruction = decode(opcode);

    try std.testing.expect(decoded.instType == .SetVx);
    try std.testing.expect(decoded.x == 0xA);
    try std.testing.expect(decoded.nn == 0x0F);
}

test "decode Call 2NNN" {
    const opcode: u16 = 0x2ABC; // 2ABC → Call subroutine at 0xABC
    const decoded: DecodedInstruction = decode(opcode);

    try std.testing.expect(decoded.instType == .Call);
    try std.testing.expect(decoded.nnn == 0xABC);
}

test "decode Jump 1NNN" {
    const opcode: u16 = 0x1234; // 1234 → Jump to 0x234
    const decoded: DecodedInstruction = decode(opcode);

    try std.testing.expect(decoded.instType == .Jump);
    try std.testing.expect(decoded.nnn == 0x234);
}

test "decode Return 00EE" {
    const opcode: u16 = 0x00EE;
    const decoded: DecodedInstruction = decode(opcode);

    try std.testing.expect(decoded.instType == .Return);
}

test "decode ClearScreen 00E0" {
    const opcode: u16 = 0x00E0;
    const decoded: DecodedInstruction = decode(opcode);

    try std.testing.expect(decoded.instType == .ClearScreen);
}
