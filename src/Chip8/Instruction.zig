pub const InstructionType = enum(u16) {
    ClearScreen = 0x00E0,
    Return = 0x00EE,
    Jump = 0x1000,
    Call = 0x2000,
    SetVx = 0x6000,
    AddVx = 0x7000,
    Unknown = 0xFFFF,
};

pub const DecodedInstruction = struct {
    instType: InstructionType,
    x: u8 = 0,
    y: u8 = 0,
    nn: u8 = 0,
    nnn: u16 = 0,
};
