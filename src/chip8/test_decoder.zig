const std = @import("std");
const decode = @import("Decoder.zig").decode;
const InstType = @import("Instruction.zig").InstructionType;

test "Decode 00E0 ClearScreen (no params)" {
    const d = decode(0x00E0);
    try std.testing.expectEqual(InstType.ClearScreen, d.inst_type);
    try std.testing.expectEqual(@as(u8, 0), d.x);
    try std.testing.expectEqual(@as(u8, 0x0E), d.y);
    try std.testing.expectEqual(@as(u8, 0xE0), d.nn);
    try std.testing.expectEqual(@as(u16, 0x0E0), d.nnn);
}

test "Decode 1NNN Jump" {
    const d = decode(0x1ABC);
    try std.testing.expectEqual(InstType.Jump, d.inst_type);
    try std.testing.expectEqual(@as(u16, 0xABC), d.nnn);
}

test "Decode 2NNN Call" {
    const d = decode(0x2345);
    try std.testing.expectEqual(InstType.Call, d.inst_type);
    try std.testing.expectEqual(@as(u16, 0x345), d.nnn);
}

test "Decode 6XNN SetVx" {
    const d = decode(0x6A0F);
    try std.testing.expectEqual(InstType.SetVx2NN, d.inst_type);
    try std.testing.expectEqual(@as(u8, 0xA), d.x);
    try std.testing.expectEqual(@as(u8, 0x0F), d.nn);
}

test "Decode 7XNN AddVx" {
    const d = decode(0x7B10);
    try std.testing.expectEqual(InstType.AddNN2Vx, d.inst_type);
    try std.testing.expectEqual(@as(u8, 0xB), d.x);
    try std.testing.expectEqual(@as(u8, 0x10), d.nn);
}

test "Decode 8XY0 Set Vx = Vy" {
    const d = decode(0x8120);
    try std.testing.expectEqual(InstType.SetVy2Vx, d.inst_type);
    try std.testing.expectEqual(@as(u8, 1), d.x);
    try std.testing.expectEqual(@as(u8, 2), d.y);
}

test "Decode 8XY4 Add Vx += Vy" {
    const d = decode(0x8AB4);
    try std.testing.expectEqual(InstType.AddVy2Vx, d.inst_type);
    try std.testing.expectEqual(@as(u8, 0xA), d.x);
    try std.testing.expectEqual(@as(u8, 0xB), d.y);
}

test "Decode ANNN Set Index Register" {
    const d = decode(0xA123);
    try std.testing.expectEqual(InstType.SetIndexReg2NNNN, d.inst_type);
    try std.testing.expectEqual(@as(u16, 0x123), d.nnn);
}

test "Decode DXYN Draw" {
    const d = decode(0xDAB5);
    try std.testing.expectEqual(InstType.Draw, d.inst_type);
    try std.testing.expectEqual(@as(u8, 0xA), d.x);
    try std.testing.expectEqual(@as(u8, 0xB), d.y);
    try std.testing.expectEqual(@as(u8, 0xB5), d.nn);
}

test "Decode FX07 SetVx2DTimer" {
    const d = decode(0xF307);
    try std.testing.expectEqual(InstType.SetVx2DTimer, d.inst_type);
    try std.testing.expectEqual(@as(u8, 3), d.x);
}

test "Decode FX65 StoreMem2Reg" {
    const d = decode(0xF565);
    try std.testing.expectEqual(InstType.StoreMem2Reg, d.inst_type);
    try std.testing.expectEqual(@as(u8, 5), d.x);
}

test "Decode Unknown high nibble" {
    const d = decode(0xF999);
    try std.testing.expectEqual(InstType.Unknown, d.inst_type);
}

test "Decode Unknown low byte in 8XY*" {
    const d = decode(0x8129);
    try std.testing.expectEqual(InstType.Unknown, d.inst_type);
}

test "Decode Unknown low byte in EX**" {
    const d = decode(0xE3FF);
    try std.testing.expectEqual(InstType.Unknown, d.inst_type);
}

test "Decode Unknown low byte in FX**" {
    const d = decode(0xF3FF);
    try std.testing.expectEqual(InstType.Unknown, d.inst_type);
}
