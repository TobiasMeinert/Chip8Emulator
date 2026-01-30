pub const InstructionType = enum(u16) {
    ClearScreen = 0x00E0, //00E0
    Return = 0x00EE, //00EE

    Jump = 0x1000, //1NNN

    Call = 0x2000, //2NNN

    SkipVxEqNN = 0x3000, //3XNN

    SkipVxNqNN = 0x400, //4XNN

    SkipVxEqVy = 0x500, //5XY0

    SetVx = 0x6000, //6XNN

    AddVx = 0x7000, //7XNN

    Set = 0x8000, //8XY0
    Or = 0x8001, //8XY1
    And = 0x8002, //8XY1
    Xor = 0x8003, //8XY3
    Add = 0x8004, //8XY4
    SubXY = 0x8005, //8XY5
    ShiftRight = 0x8006, //8XY6
    SubYX = 0x8007, //8XY7
    ShiftLeft = 0x800E, //8XYE

    SkipVxNqVy = 0x900, //9XYO

    SetIndexReg = 0xA000, //ANNN

    JumpWithOffset = 0xB00, //BNNN

    Random = 0xC00, //CXNN

    Draw = 0xD000, //DXYN

    SkipVxPressed = 0xE09E, //EX9E
    SkipVxNotPressed = 0xE0A1,
    opcodA1, //EXA1

    SetVx2DTimer = 0xF007, //FX07
    Wait4Key = 0xF00A, //FX0A
    SetDTimer2VX = 0xF015, //FX15
    SetSTimer2VX = 0xF018, //FX18
    AddToIndex = 0xF01E, //FX1E
    FontChar = 0xF029, //FX29
    DecimalConversion = 0xF033, //FX33
    StoreReg2Mem = 0xF055, //FX55
    StoreMem2Reg = 0x065, //FX65

    Unknown = 0xFFFF,
};

pub const DecodedInstruction = struct {
    inst_type: InstructionType,
    x: u8,
    y: u8,
    nn: u8,
    nnn: u16,

    pub fn init(instruction_type: InstructionType, opcode: u16) DecodedInstruction {
        return .{
            .inst_type = instruction_type,
            .x = @intCast((opcode & 0x0F00) >> 8),
            .y = @intCast((opcode & 0x00F0) >> 4),
            .nn = @intCast((opcode & 0x00FF)),
            .nnn = @intCast((opcode & 0x0FFF)),
        };
    }
};
