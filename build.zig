const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const chip8 = b.addModule("chip8", .{
        .root_source_file = b.path("src/chip8/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "Chip8Emulator",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    exe.root_module.addImport("chip8", chip8);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_setp = b.step("run", "Run the Emulator.");
    run_setp.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run unit tests");
    const unit_tetst = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/test.zig"),
            .target = target,
        }),
    });
    const run_unit_tests = b.addRunArtifact(unit_tetst);
    test_step.dependOn(&run_unit_tests.step);
}
