const std = @import("std");
const print = std.debug.print;

const space: u8 = 32;
const hash: u8 = 35;
const new_line: u8 = 13;
const letterB: u8 = 66;
const letterA: u8 = 65;

pub const TerminalUi = struct {
    io: std.Io,
    stdout_buffer: [8192]u8 = undefined,
    stdout_writer: std.Io.File.Writer = undefined,

    draw_matrix: *[32][64]u1,
    draw_flag: *std.atomic.Value(bool),
    width: usize = 64,
    height: usize = 32,

    pub fn init(io: std.Io, draw_matrix: *[32][64]u1, draw_flag: *std.atomic.Value(bool)) TerminalUi {
        var ui = TerminalUi{
            .io = io,
            .draw_matrix = draw_matrix,
            .draw_flag = draw_flag,
        };
        ui.stdout_writer = std.Io.File.stdout().writer(ui.io, &ui.stdout_buffer);
        return ui;
    }

    pub fn renderFrame(self: *TerminalUi) void {
        var index: usize = 0;
        if (self.draw_flag.load(.monotonic)) {
            // clearScreen();
            var draw_string: [32 * (64 * 2 + 1)]u8 = undefined;
            for (self.draw_matrix) |row| {
                for (row) |cell| {
                    if (cell > 0) {
                        draw_string[index] = hash;
                        index += 1;
                        draw_string[index] = hash;
                    } else {
                        draw_string[index] = space;
                        index += 1;
                        draw_string[index] = space;
                    }
                    index += 1;
                }
                draw_string[index] = new_line;
                index += 1;
            }
            self.writeFrame(draw_string[0..index]);
            self.draw_flag.store(false, .monotonic);
        }
    }

    fn writeFrame(self: *TerminalUi, draw_string: []const u8) void {
        self.stdout_writer.interface.writeAll("\x1b[H") catch {};
        self.stdout_writer.interface.writeAll(draw_string) catch {};
        self.stdout_writer.interface.flush() catch {};
    }
};

// test "Simple ui test" {
//     var matrix: [32][64]u1 = @splat(@splat(0));
//     var flag: std.atomic.Value(bool) = .init(false);
//
//     var ui = TerminalUi.init(&matrix, &flag);
//     ui.renderFrame();
//     var threaded: std.Io.Threaded = .init_single_threaded;
//     const io = threaded.io();
//
//     try io.sleep(.fromSeconds(5), std.Io.Clock.real);
//     matrix = @splat(@splat(1));
//     ui.renderFrame();
//     try io.sleep(.fromSeconds(10), std.Io.Clock.real);
// }
