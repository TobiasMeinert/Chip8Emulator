const std = @import("std");

const chip8 = @import("chip8/root.zig");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();

    var chip = chip8.Chip8.init(true);

    const cpu_hz = 700;
    const timer_hz = 60;

    const cpu_step_ns = 1_000_000_000 / cpu_hz;
    const timer_step_ns = 1_000_000_000 / timer_hz;

    var cpu_timer = try std.time.Timer.start();
    var timer_timer = try std.time.Timer.start();

    while (true) {
        std.debug.print("Hello World xD", .{});
        if (cpu_timer.read() >= cpu_step_ns) {
            cpu_timer.reset();
            const opcode = try chip.fetchOpCode();
            std.debug.print("Got Opcode: {}", .{opcode});
            const instruction = chip8.Decoder.decode(opcode);
            try chip8.Executer.execute(&chip, instruction);
        }
        if (timer_timer.read() >= timer_step_ns) {
            timer_timer.reset();

            if (chip.delay_timer > 0) chip.delay_timer -= 1;
            if (chip.sound_timer > 0) chip.delay_timer -= 1;
        }
        try io.sleep(.fromNanoseconds(500), std.Io.Clock.real);
    }
}
