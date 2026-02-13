const std = @import("std");

pub const Keypad = struct {
    keys: std.atomic.Value(u16) = .init(0x00),

    pub fn press(self: *Keypad, key: u16) void {
        self.keys.store(key, .monotonic);
    }

    pub fn release(self: *Keypad, key: u16) void {
        const new_state = self.keys.load(.monotonic) & ~key;
        self.keys.store(new_state, .monotonic);
    }

    pub fn isPressed(self: *Keypad, key: u16) bool {
        return (self.keys.load(.monotonic) & key) > 0;
    }

    pub fn resetKeys(self: *Keypad) void {
        self.keys.store(0x00, .monotonic);
    }
};

test "Keypad release" {
    var keyboard = Keypad{};

    keyboard.keys.store(0b0000_1111, .monotonic);

    keyboard.release(0b1111_0101);

    try std.testing.expectEqual(0b0000_1010, keyboard.keys.load(.monotonic));
}

test "Keypad isPressed" {
    var keyboard = Keypad{};
    keyboard.keys.store(0b0101, .monotonic);

    try std.testing.expectEqual(true, keyboard.isPressed(0b0101));
    try std.testing.expectEqual(true, keyboard.isPressed(0b0001));
    try std.testing.expectEqual(false, keyboard.isPressed(0b0111));
}
