const std = @import("std");

const Chip8 = @import("chip8/root.zig");
const TerminalUi = @import("platform/terminalUI/root.zig").TerminalUi;
const TerminalInput = @import("platform/terminalInput/root.zig").Terminal;

// pub fn main(init: std.process.Init) !void {
pub fn main(init: std.process.Init) !void {
    // Setutp
    // std
    var chip = Chip8.Chip8.init(true);
    var terminalInput = try TerminalInput.init(&chip.keys.keys);
    defer terminalInput.disableRawMode();

    try terminalInput.enableRawMode();
    const cpu_hz = 300;
    const timer_hz = 60;
    const cpu_step_ns = 1_000_000_000 / cpu_hz;
    const timer_step_ns = 1_000_000_000 / timer_hz;

    var cpu_timer = try std.time.Timer.start();
    var timer_timer = try std.time.Timer.start();

    var ui = TerminalUi.init(init.io, &chip.vram, &chip.draw_flag);
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    const rom_path = args.ptr[1];
    const rom: []u8 = try loadROM(init.io, rom_path);
    try chip.loadRom(rom);
    // chip.dumpRam(0x0, Chip8.Chip8.ram_size);

    // Loop
    while (true) {
        if (cpu_timer.read() >= cpu_step_ns) {
            cpu_timer.reset();
            // try terminalInput.handleInput();
            const opcode = try chip.fetchOpCode();
            const instruction = Chip8.Decoder.decode(opcode);
            try Chip8.Executer.execute(&chip, instruction);
        }
        if (timer_timer.read() >= timer_step_ns) {
            timer_timer.reset();

            if (chip.delay_timer > 0) chip.delay_timer -= 1;
            if (chip.sound_timer > 0) chip.sound_timer -= 1;
            ui.renderFrame();
        }
        try init.io.sleep(.fromNanoseconds(500), std.Io.Clock.real);
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
    const rom = try file_reader.interface.readAlloc(gpa, len);
    return rom;
}
