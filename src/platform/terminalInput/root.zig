const std = @import("std");
const c = @cImport({
    @cInclude("unistd.h");
    @cInclude("termios.h");
});
pub const Terminal = struct {
    orig_termios: c.struct_termios,
    input_buffer: [1]u8 = undefined,
    chip_key_adress: *std.atomic.Value(u16),

    pub fn init(key_adress: *std.atomic.Value(u16)) !Terminal {
        var self = Terminal{ .orig_termios = undefined, .chip_key_adress = key_adress };
        if (c.tcgetattr(0, &self.orig_termios) != 0) {
            return terminalError.TermiosGetFailed;
        }
        return self;
    }

    pub fn handleInput(self: *Terminal) !void {
        const n = std.posix.read(std.posix.STDIN_FILENO, &self.input_buffer) catch |err| {
            std.debug.print("Got an error?: {}", .{err});
            return;
        };
        if (n == 1) {
            const key_value: u16 = @intCast(self.input_buffer[0]);
            const key: KeyMapping = @enumFromInt(key_value);
            switch (key) {
                KeyMapping.one => self.chip_key_adress.store(1 << 0, .monotonic),
                KeyMapping.two => self.chip_key_adress.store(1 << 1, .monotonic),
                KeyMapping.three => self.chip_key_adress.store(1 << 2, .monotonic),
                KeyMapping.c => self.chip_key_adress.store(1 << 3, .monotonic),

                KeyMapping.four => self.chip_key_adress.store(1 << 4, .monotonic),
                KeyMapping.five => self.chip_key_adress.store(1 << 5, .monotonic),
                KeyMapping.six => self.chip_key_adress.store(1 << 6, .monotonic),
                KeyMapping.d => self.chip_key_adress.store(1 << 7, .monotonic),

                KeyMapping.seven => self.chip_key_adress.store(1 << 8, .monotonic),
                KeyMapping.eight => self.chip_key_adress.store(1 << 9, .monotonic),
                KeyMapping.nine => self.chip_key_adress.store(1 << 10, .monotonic),
                KeyMapping.e => self.chip_key_adress.store(1 << 11, .monotonic),

                KeyMapping.a => self.chip_key_adress.store(1 << 12, .monotonic),
                KeyMapping.null => self.chip_key_adress.store(1 << 13, .monotonic),
                KeyMapping.b => self.chip_key_adress.store(1 << 14, .monotonic),
                KeyMapping.f => self.chip_key_adress.store(1 << 15, .monotonic),
                _ => std.debug.print("Got wrong key input\n", .{}),
            }
        }
    }

    pub fn enableRawMode(self: *Terminal) !void {
        var raw = self.orig_termios;
        const lflag: c_uint = @bitCast(c.ECHO | c.ICANON | c.IEXTEN);
        const iflag: c_uint = @bitCast(c.IXON | c.ICRNL | c.BRKINT | c.INPCK | c.ISTRIP);
        const oflag: c_uint = @bitCast(c.OPOST);
        raw.c_lflag &= ~lflag;
        raw.c_iflag &= ~iflag;
        raw.c_oflag &= ~oflag;
        raw.c_cflag |= c.CS8;

        raw.c_cc[c.VMIN] = 0;
        raw.c_cc[c.VTIME] = 1; // 100ms timeout
        if (c.tcsetattr(0, c.TCSAFLUSH, &raw) != 0) {
            return terminalError.TermiosSetFailed;
        }
        std.debug.print("\x1b[2J", .{});
    }

    pub fn disableRawMode(self: *Terminal) void {
        _ = c.tcsetattr(0, c.TCSAFLUSH, &self.orig_termios);
    }
};

const terminalError = error{
    TermiosGetFailed,
    TermiosSetFailed,
    ProgramExit,
};

pub const KeyMapping = enum(u16) {
    one = 49, // 1
    two = 50, // 2
    three = 51, // 3
    c = 52, // 4

    four = 113, // q
    five = 119, // w
    six = 101, // e
    d = 114, // r

    seven = 97, // a
    eight = 115, // s
    nine = 100, // d
    e = 102, // f

    a = 61, // \
    null = 122, // z
    b = 120, // x
    f = 99, // c
    _,
};
