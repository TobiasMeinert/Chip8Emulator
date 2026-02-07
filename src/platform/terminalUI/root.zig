const std = @import("std");
const print = std.debug.print;

const space: u8 = 32;
const hash: u8 = 35;
const new_line: u8 = 10;
const letterB: u8 = 66;
const letterA: u8 = 65;

pub const TerminalUi = struct {
    draw_matrix: *[32][64]u1,
    draw_string: [(32 * 2 + 1) * 64]u8 = @splat(space), //we use 2 pixels for the width and we need +1 vor new line
    draw_flag: *std.atomic.Value(bool),
    width: usize = 64,
    height: usize = 32,

    pub fn init(draw_matrix: *[32][64]u1, draw_flag: *std.atomic.Value(bool)) TerminalUi {
        return .{
            .draw_matrix = draw_matrix,
            .draw_flag = draw_flag,
        };
    }

    pub fn renderFrame(self: *TerminalUi) void {
        if (self.draw_flag.load(.monotonic)) {
            clearScreen();
            var index: usize = 0;
            for (self.draw_matrix) |row| {
                for (row) |cell| {
                    if (cell > 0) {
                        self.draw_string[index] = hash;
                        index += 1;
                        self.draw_string[index] = hash;
                    } else {
                        self.draw_string[index] = space;
                        index += 1;
                        self.draw_string[index] = space;
                    }
                    index += 1;
                }
                self.draw_string[index] = new_line;
                index += 1;
            }
            print("\n{s}", .{self.draw_string});
            self.draw_flag.store(false, .monotonic);
        }
    }
};

fn clearScreen() void {
    std.debug.print("\x1b[2J\x1b[H", .{});
}

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
