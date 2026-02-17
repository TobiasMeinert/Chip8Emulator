const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const sdl_dep = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
        //.preferred_linkage = .static,
        //.strip = null,
        //.sanitize_c = null,
        //.pic = null,
        //.lto = null,
        //.emscripten_pthreads = false,
    });
    const sdl_lib = sdl_dep.artifact("SDL3");
    // const sdl_test_lib = sdl_dep.artifact("SDL3_test");

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
            // .link_libc = true,
        }),
    });
    exe.root_module.addImport("chip8", chip8);
    exe.root_module.linkLibrary(sdl_lib);
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
