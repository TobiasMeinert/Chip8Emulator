const std = @import("std");
const Keypad = @import("Keypad.zig").Keypad;

pub const Chip8 = struct {
    ram: [ram_size]u8 = @splat(0),
    register: [16]u8 = @splat(0),
    index_register: u16 = 0,
    program_counter: u16 = 0x200,
    stack: [16]u16 = @splat(0),
    stackpointer: u8 = 0,
    delay_timer: u8 = 0,
    sound_timer: u8 = 0,
    original: bool = true,

    vram: [32][64]u1 = @splat(@splat(0)),
    draw_flag: std.atomic.Value(bool) = .init(false),

    keys: Keypad = Keypad{},

    pub const ram_size = 4096;
    pub const program_start = 0x200;
    pub const program_space = ram_size - program_start;
    pub const fontset_start = 0x50;

    pub fn init(original: bool) Chip8 {
        var chip = Chip8{ .original = original };

        chip.loadFont(&fontset);
        return chip;
    }

    pub fn loadRom(self: *Chip8, data: []const u8) !void {
        if (data.len > program_space) {
            return Chip8Error.RomToBig;
        }
        for (0..data.len) |i| {
            self.ram[program_start + i] = data[i];
        }
    }

    fn loadFont(self: *Chip8, data: []const u8) void {
        for (0..data.len) |i| {
            self.ram[fontset_start + i] = data[i];
        }
    }

    pub fn dumpRam(self: *const Chip8, start: usize, end: usize) void {
        // Grenzen prüfen
        const safe_start = if (start < self.ram.len) start else self.ram.len;
        const safe_end = if (end <= self.ram.len) end else self.ram.len;

        for (safe_start..safe_end) |i| {
            const byte = self.ram[i];

            // Neue Zeile + Adressoffset
            if ((i - safe_start) % 16 == 0) {
                if (i != safe_start) std.debug.print("\n", .{});
                std.debug.print("{X:0>4}: ", .{i});
            }

            // Byte in Hex
            std.debug.print("{X:0>2}", .{byte});

            // Nach je 4 Bytes extra Space
            if ((i - safe_start) % 4 == 3) {
                std.debug.print("  ", .{});
            } else {
                std.debug.print(" ", .{});
            }
        }

        std.debug.print("\n", .{});
    }

    pub fn fetchOpCode(self: *Chip8) !u16 {
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
    WrongFonsetData,
};

const fontset = [_]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};

test "Chip8 loadRom" {
    var my_chip = Chip8.init(true);
    const rom = [_]u8{ 0x12, 0x42, 0x34, 0xFF };
    try my_chip.loadRom(&rom);
    try std.testing.expectEqual(0x12, my_chip.ram[0x200]);
    try std.testing.expectEqual(0x34, my_chip.ram[0x200 + 2]);
}

test "Chip8 throw RomToBig" {
    var my_chip = Chip8.init(true);
    const rom: [Chip8.ram_size]u8 = @splat(0xA);
    try std.testing.expectError(Chip8Error.RomToBig, my_chip.loadRom(&rom));
}

test "Chip8 fetchOpCode" {
    var my_chip = Chip8.init(true);
    const rom = [_]u8{ 0x12, 0x34, 0xAA, 0xFF };
    try my_chip.loadRom(&rom);
    try std.testing.expectEqual(0x1234, my_chip.fetchOpCode());
    try std.testing.expectEqual(0xAAFF, my_chip.fetchOpCode());
}

test "Chip8 fetchOpCode OutOfScopeError" {
    var my_chip = Chip8.init(true);
    my_chip.program_counter = Chip8.ram_size;
    try std.testing.expectError(Chip8Error.ProgramCounterOutOfScope, my_chip.fetchOpCode());
}
