const std = @import("std");

const Chip8 = struct {
    ram: [ram_size]u8 = [_]u8{0} ** ram_size,
    register: [16]u8 = [_]u8{0} ** 16,
    index_register: u16 = 0,
    program_counter: u16 = 0x200,
    stack: [16]u16 = [_]u16{0} ** 16,
    stackpointer: u8 = 0,
    delay_timer: u8 = 0,
    sound_timer: u8 = 0,

    const ram_size = 4096;
    const program_start = 0x200;
    const program_space = ram_size - program_start;

    pub fn init() Chip8 {
        return Chip8{};
    }

    pub fn loadRom(self: *Chip8, data: []const u8) !void {
        if (data.len > program_space) {
            return Chip8Error.RomToBig;
        }
        for (0..data.len) |i| {
            self.ram[program_start + i] = data[i];
        }
    }

    fn fetchOpCode(self: *Chip8) !u16 {
        if (self.program_counter > ram_size - 2) {
            return Chip8Error.ProgramCounterOutOfScope;
        }

        const hi_byte = self.ram[self.program_counter];
        const lo_byte = self.ram[self.program_counter + 1];
        self.program_counter += 2;

        const op_code: u16 = (@as(u16, hi_byte) << 8) | @as(u16, lo_byte);
        return op_code;
    }
};

const Chip8Error = error{
    RomToBig,
    ProgramCounterOutOfScope,
};

test "Chip8 loadRom" {
    var my_chip = Chip8.init();
    const rom: []const u8 = &[_]u8{ 0x12, 0x34 };
    try my_chip.loadRom(rom);
    try std.testing.expectEqual(0x12, my_chip.ram[0x200]);
    try std.testing.expectEqual(0x34, my_chip.ram[0x200 + 1]);
}

test "Chip8 throw RomToBig" {
    var my_chip = Chip8.init();
    const rom: []const u8 = &[_]u8{ 0x12, 0x34 } ** Chip8.ram_size;
    try std.testing.expectError(Chip8Error.RomToBig, my_chip.loadRom(rom));
}

test "Chip8 fetchOpCode" {
    var my_chip = Chip8.init();
    const rom: []const u8 = &[_]u8{ 0x12, 0x34, 0xAA, 0xFF };
    try my_chip.loadRom(rom);
    try std.testing.expectEqual(0x1234, my_chip.fetchOpCode());
    try std.testing.expectEqual(0xAAFF, my_chip.fetchOpCode());
}

test "Chip8 fetchOpCode OutOfScopeError" {
    var my_chip = Chip8.init();
    my_chip.program_counter = Chip8.ram_size;
    try std.testing.expectError(Chip8Error.ProgramCounterOutOfScope, my_chip.fetchOpCode());
}
