const std = @import("std");

pub const Package = struct {
    pub const Options = struct {
        api: enum {
            raw,
            wrapper,
        } = .raw,
    };

    options: Options,
    zopengl: *std.Build.Module,
    zopengl_options: *std.Build.Module,
    zopengl_lib: *std.Build.CompileStep,

    pub fn build(
        b: *std.Build,
        target: std.zig.CrossTarget,
        optimize: std.builtin.Mode,
        args: struct {
            options: Options = .{},
        },
    ) Package {
        const options_step = b.addOptions();
        inline for (std.meta.fields(Options)) |option_field| {
            const option_val = @field(args.options, option_field.name);
            options_step.addOption(@TypeOf(option_val), option_field.name, option_val);
        }

        const options = options_step.createModule();

        const zopengl = b.createModule(.{
            .source_file = .{ .path = thisDir() ++ "/src/zopengl.zig" },
            .dependencies = &.{
                .{ .name = "zopengl_options", .module = options },
            },
        });

        const zopengl_lib = b.addSharedLibrary(.{
            .name = "zopengl",
            .target = target,
            .optimize = optimize,
        });
        zopengl_lib.addOptions("zopengl_options", options_step);
        zopengl_lib.addObjectFile(thisDir() ++ "/src/zopengl.zig");

        return .{
            .options = args.options,
            .zopengl = zopengl,
            .zopengl_options = options,
            .zopengl_lib = zopengl_lib,
        };
    }

    pub fn link(zopengl_pkg: Package, exe: *std.Build.CompileStep) void {
        exe.linkLibrary(zopengl_pkg.zopengl_lib);
    }
};

pub fn build(_: *std.Build) void {}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
