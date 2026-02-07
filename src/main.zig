const std = @import("std");

const Chip8 = @import("chip8/root.zig");
const TerminalUi = @import("platform/terminalUI/root.zig").TerminalUi;

pub fn main() !void {
    // Setutp
    // std
    var threaded: std.Io.Threaded = .init_single_threaded;
    defer threaded.deinit();
    const io = threaded.io();

    var chip = try Chip8.Chip8.init(true);
    const cpu_hz = 700;
    const timer_hz = 60;
    const cpu_step_ns = 1_000_000_000 / cpu_hz;
    const timer_step_ns = 1_000_000_000 / timer_hz;

    var cpu_timer = try std.time.Timer.start();
    var timer_timer = try std.time.Timer.start();

    var ui = TerminalUi.init(&chip.vram, &chip.draw_flag);
    const args = std.os.argv();
    const rom_path = args[1];
    const rom: []u8 = try loadROM(io, rom_path);
    try chip.loadRom(rom);
    chip.dumpRam(0x0, Chip8.Chip8.ram_size);

    // Loop
    while (true) {
        if (cpu_timer.read() >= cpu_step_ns) {
            cpu_timer.reset();
            const opcode = try chip.fetchOpCode();
            const instruction = Chip8.Decoder.decode(opcode);
            try Chip8.Executer.execute(&chip, instruction);
        }
        if (timer_timer.read() >= timer_step_ns) {
            timer_timer.reset();

            if (chip.delay_timer > 0) chip.delay_timer -= 1;
            if (chip.sound_timer > 0) chip.delay_timer -= 1;
            ui.renderFrame();
        }
        try io.sleep(.fromNanoseconds(500), std.Io.Clock.real);
    }
}

fn loadROM(io: std.Io, rom_path: []const u8) ![]u8 {
    var gpa = std.heap.page_allocator;
    const dir = std.Io.Dir.cwd();
    const rom_file = try std.Io.Dir.openFile(dir, io, rom_path, .{ .mode = .read_only });
    defer rom_file.close(io);
    const len = try rom_file.length(io);

    const buffer = try gpa.alloc(u8, Chip8.Chip8.program_space);

    var file_reader = rom_file.reader(io, buffer);
    // file_reader.interface:
    const rom = try file_reader.interface.readAlloc(gpa, len);
    return rom;
}
