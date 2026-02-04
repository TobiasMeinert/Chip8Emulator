pub const InstructionType = enum(u16) {
    /// 00E0 — Clear the screen
    ClearScreen = 0x00E0,

    /// 00EE — Return from subroutine
    Return = 0x00EE,

    /// 1NNN — Jump to address NNN
    Jump = 0x1000,

    /// 2NNN — Call subroutine at NNN
    Call = 0x2000,

    /// 3XNN — Skip next instruction if VX == NN
    SkipVxEqNN = 0x3000,

    /// 4XNN — Skip next instruction if VX != NN
    SkipVxNqNN = 0x4000,

    /// 5XY0 — Skip next instruction if VX == VY
    SkipVxEqVy = 0x5000,

    /// 6XNN — Set VX to NN
    SetVx2NN = 0x6000,

    /// 7XNN — Add NN to VX (no carry)
    AddNN2Vx = 0x7000,

    /// 8XY0 — Set VX = VY
    SetVy2Vx = 0x8000,

    /// 8XY1 — Set VX = VX OR VY
    Or = 0x8001,

    /// 8XY2 — Set VX = VX AND VY
    And = 0x8002,

    /// 8XY3 — Set VX = VX XOR VY
    Xor = 0x8003,

    /// 8XY4 — Add VY to VX, VF = carry
    AddVy2Vx = 0x8004,

    /// 8XY5 — Subtract VY from VX, VF = NOT borrow
    SubVyFromVx = 0x8005,

    /// 8XY6 — Shift VX right by 1, VF = LSB before shift
    ShiftRight = 0x8006,

    /// 8XY7 — Set VX = VY - VX, VF = NOT borrow
    SubVxFromVy = 0x8007,

    /// 8XYE — Shift VX left by 1, VF = MSB before shift
    ShiftLeft = 0x800E,

    /// 9XY0 — Skip next instruction if VX != VY
    SkipVxNqVy = 0x9000,

    /// ANNN — Set index register I = NNN
    SetIndexReg2NNNN = 0xA000,

    /// BNNN — Jump to address NNN + V0
    JumpWithOffset = 0xB000,

    /// CXNN — Set VX = random byte AND NN
    Random = 0xC000,

    /// DXYN — Draw sprite at (VX, VY) with N bytes of sprite data
    Draw = 0xD000,

    /// EX9E — Skip next instruction if key VX is pressed
    SkipVxPressed = 0xE09E,

    /// EXA1 — Skip next instruction if key VX is not pressed
    SkipVxNotPressed = 0xE0A1,

    /// FX07 — Set VX = delay timer value
    SetVx2DTimer = 0xF007,

    /// FX0A — Wait for a key press and store in VX
    Wait4Key = 0xF00A,

    /// FX15 — Set delay timer = VX
    SetDTimer2VX = 0xF015,

    /// FX18 — Set sound timer = VX
    SetSTimer2VX = 0xF018,

    /// FX1E — Add VX to index register
    AddToIndex = 0xF01E,

    /// FX29 — Set I = location of sprite for digit VX
    FontChar = 0xF029,

    /// FX33 — Store BCD representation of VX in memory at I, I+1, I+2
    DecimalConversion = 0xF033,

    /// FX55 — Store registers V0 through VX in memory starting at I
    StoreReg2Mem = 0xF055,

    /// FX65 — Read registers V0 through VX from memory starting at I
    StoreMem2Reg = 0xF065,

    /// Unknown instruction / unimplemented opcode
    Unknown = 0xFFFF,
};
pub const DecodedInstruction = struct {
    inst_type: InstructionType,
    x: u8,
    y: u8,
    n: u8,
    nn: u8,
    nnn: u16,

    pub fn init(instruction_type: InstructionType, opcode: u16) DecodedInstruction {
        return .{
            .inst_type = instruction_type,
            .x = @intCast((opcode & 0x0F00) >> 8),
            .y = @intCast((opcode & 0x00F0) >> 4),
            .n = @intCast(opcode & 0x000F),
            .nn = @intCast((opcode & 0x00FF)),
            .nnn = @intCast((opcode & 0x0FFF)),
        };
    }
};
