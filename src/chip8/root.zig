const std = @import("std");
const Io = std.Io;

pub const Chip8 = @import("Chip8.zig").Chip8;
pub const Decoder = @import("Decoder.zig");
pub const Executer = @import("Executer.zig");
test "Testing Time itself o.O" {
    var timer = try std.time.Timer.start();
    const time = timer.read();
    std.debug.print("Got the Time: {}", .{time});
    // const opcode = try chip.fetchOpCode();
    // const instruction = Decoder.decode(opcode);
    // try Executer.execute(chip, instruction);
}
pub fn controler_loop(chip: *Chip8) !void {
    const opcode = try chip.fetchOpCode();
    const instruction = Decoder.decode(opcode);
    try Executer.execute(chip, instruction);
}

// We keep it for when we figure out mutli thread
//
//
// pub fn cpuLoop(chip: *Chip8, io: *Io) !void {
//     while (true) {
//         const opcode = try chip.fetchOpCode();
//         const instruction = Decoder.decode(opcode);
//         try Executer.execute(chip, instruction);
//         try io.sleep(.fromNanoseconds(1_428_571), .awake);
//     }
// }

// pub fn timerLoop(chip: *Chip8, io: *Io) !void {
//     while (true) {
//         if (chip.delay_timer > 0) {
//             chip.delay_timer -= 1;
//         }
//         if (chip.sound_timer) {
//             chip.sound_timer -= 1;
//         }
//         try io.sleep(.fromMilliseconds(16), .awake);
//     }
// }
