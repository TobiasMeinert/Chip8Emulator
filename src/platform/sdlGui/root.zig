const std = @import("std");
const builtin = @import("builtin");
const c = @cImport({
    @cDefine("SDL_DISABLE_OLD_NAMES", {});
    @cInclude("SDL3/SDL.h");
    @cDefine("SDL_MAIN_HANDLED", {});
    @cInclude("SDL3/SDL_main.h");
});

const GRID_WIDTH: c_int = 64;
const GRID_H: c_int = 32;
const CELL_SIZE: c_int = 15;

pub const SdlGui = struct {
    window: *c.SDL_Window = undefined,
    renderer: *c.SDL_Renderer = undefined,
    fully_initialized: bool = false,

    frame_buffer: *[GRID_H][GRID_WIDTH]u1,
    draw_flag: std.atomic.Value(bool),

    keys: *std.atomic.Value(u16),
    running: *std.atomic.Value(bool),

    pub fn init(running: *std.atomic.Value(bool), frame_buffer: *[GRID_H][GRID_WIDTH]u1, draw_flag: std.atomic.Value(bool), keys: *std.atomic.Value(u16)) !SdlGui {
        var gui = SdlGui{
            .running = running,
            .frame_buffer = frame_buffer,
            .draw_flag = draw_flag,
            .keys = keys,
        };
        try errify(c.SDL_Init(c.SDL_INIT_VIDEO));
        try errify(c.SDL_CreateWindowAndRenderer(
            "Chip8Emu",
            CELL_SIZE * GRID_WIDTH,
            CELL_SIZE * GRID_H,
            0,
            @ptrCast(&gui.window),
            @ptrCast(&gui.renderer),
        ));

        try errify(c.SDL_SetRenderDrawBlendMode(gui.renderer, c.SDL_BLENDMODE_NONE));
        gui.fully_initialized = true;
        return gui;
    }

    pub fn deinit(self: *SdlGui) void {
        c.SDL_DestroyRenderer(self.renderer);
        c.SDL_DestroyWindow(self.window);
        c.SDL_Quit();
    }

    pub fn pump(self: *SdlGui) !void {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) {
            switch (event.type) {
                c.SDL_EVENT_QUIT => {
                    self.running.store(false, .monotonic);
                },
                c.SDL_EVENT_KEY_DOWN => {
                    if (mapChip8Key(event.key.key)) |key| {
                        self.setKey(key, true);
                    }
                },
                c.SDL_EVENT_KEY_UP => {
                    if (mapChip8Key(event.key.key)) |key| {
                        self.setKey(key, false);
                    }
                },
                else => {},
            }
        }
        if (self.running.load(.monotonic)) {
            try self.draw();
        }
    }

    fn draw(self: *SdlGui) !void {
        try errify(c.SDL_SetRenderDrawColor(self.renderer, 0, 0, 0, 255));
        try errify(c.SDL_RenderClear(self.renderer));

        for (0..GRID_H) |h| {
            for (0..GRID_WIDTH) |w| {
                if (self.frame_buffer[h][w] == 1) {
                    try errify(c.SDL_SetRenderDrawColor(self.renderer, 240, 240, 240, 255));
                } else {
                    try errify(c.SDL_SetRenderDrawColor(self.renderer, 10, 10, 10, 255));
                }
                const rect = c.SDL_FRect{
                    .x = @floatFromInt(w * CELL_SIZE),
                    .y = @floatFromInt(h * CELL_SIZE),
                    .w = CELL_SIZE,
                    .h = CELL_SIZE,
                };
                try errify(c.SDL_RenderFillRect(self.renderer, &rect));
            }
        }
        try errify(c.SDL_RenderPresent(self.renderer));
    }

    fn setKey(self: *SdlGui, key: u4, value: bool) void {
        std.debug.print("setting Key", .{});
        const mask: u16 = @as(u16, 1) << key;
        while (true) {
            const old = self.keys.load(.monotonic);
            const new = if (value) (old | mask) else (old & ~mask);
            if (self.keys.cmpxchgWeak(old, new, .acq_rel, .monotonic) == null) {
                break;
            }
        }
    }
};

inline fn errify(value: anytype) error{SdlError}!void {
    if (!value) return error.SdlError;
}

fn mapChip8Key(sym: c.SDL_Keycode) ?u4 {
    return switch (sym) {
        c.SDLK_1 => 0x1,
        c.SDLK_2 => 0x2,
        c.SDLK_3 => 0x3,
        c.SDLK_4 => 0xC,

        c.SDLK_Q => 0x4,
        c.SDLK_W => 0x5,
        c.SDLK_E => 0x6,
        c.SDLK_R => 0xD,

        c.SDLK_A => 0x7,
        c.SDLK_S => 0x8,
        c.SDLK_D => 0x9,
        c.SDLK_F => 0xE,

        c.SDLK_Z => 0xA,
        c.SDLK_X => 0x0,
        c.SDLK_C => 0xB,
        c.SDLK_V => 0xF,

        else => null,
    };
}
