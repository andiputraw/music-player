const std = @import("std");
const ray = @import("./raylib.zig");
const builtin = @import("builtin");
const fileDialog = @import("tinyfiledialog.zig");
const appState = @import("./state.zig");
const miniaudio = @cImport({
    @cInclude("miniaudio.h");
});
const c = @cImport({
    @cInclude("stdio.h");
});

// fn audio() void {
//     var engine: miniaudio.ma_engine = undefined;
//     const result = miniaudio.ma_engine_init(null, &engine);
//     defer miniaudio.ma_engine_uninit(&engine);

//     if (result != miniaudio.MA_SUCCESS) {
//         return error.MINIAUDIO_FAIL_INIT;
//     }

//     _ = miniaudio.ma_engine_play_sound(&engine, "swirls-of-shamsir.mp3", null);
//     _ = c.printf("Press enter to quit...");
//     _ = c.getchar();
// }

const getStateT = *const fn () callconv(.C) appState.StateType;
const setStateT = *const fn (appState.StateType) callconv(.C) void;
const loopT = *const fn () void;
const initT = *const fn () void;
const cleanupT = *const fn () void;
const onResizeT = *const fn () void;

extern "c" fn dlerror() ?[*:0]const u8;

const GameSymbol = struct {
    game_lib: std.DynLib,
    innerGetState: getStateT,
    innerSetState: setStateT,
    innerLoop: loopT,
    innerInit: initT,
    innerCleanup: cleanupT,
    innerOnResize: onResizeT,

    pub fn new() GameSymbol {
        var game_lib = std.DynLib.open("zig-out/lib/libloop.so") catch {
            const err = dlerror() orelse "Unknown error";
            std.debug.print("Failed to open libloop.so: {s}\n", .{err});
            @panic("Failed to open libloop.so");
        };
        const initFn = game_lib.lookup(initT, "init") orelse @panic("Failed to get init symbol");

        initFn();

        return GameSymbol{
            .game_lib = game_lib,
            .innerGetState = game_lib.lookup(getStateT, "getState") orelse @panic("Failed to get getState sybmol"),
            .innerSetState = game_lib.lookup(setStateT, "setState") orelse @panic("Failed to get setState symbol"),
            .innerLoop = game_lib.lookup(loopT, "loop") orelse @panic("Failed to get loop symbol"),
            .innerInit = initFn,
            .innerCleanup = game_lib.lookup(cleanupT, "cleanup") orelse @panic("Failed to get cleanup symbol"),
            .innerOnResize = game_lib.lookup(onResizeT, "onResize") orelse @panic("Failed to get onResize symbol"),
        };
    }

    pub fn reload(self: *GameSymbol) !void {
        const state = self.innerGetState();
        self.innerCleanup();
        self.game_lib.close();
        var game_lib = try std.DynLib.open("zig-out/lib/libloop.so");
        self.game_lib = game_lib;
        self.innerGetState = game_lib.lookup(getStateT, "getState") orelse unreachable;
        self.innerSetState = game_lib.lookup(setStateT, "setState") orelse unreachable;
        self.innerLoop = game_lib.lookup(loopT, "loop") orelse unreachable;
        self.innerInit = game_lib.lookup(initT, "init") orelse unreachable;
        self.innerCleanup = game_lib.lookup(cleanupT, "cleanup") orelse unreachable;
        self.innerOnResize = game_lib.lookup(onResizeT, "onResize") orelse unreachable;

        self.innerInit();
        self.innerSetState(state);
    }
    pub fn onResize(self: *GameSymbol) void {
        self.innerOnResize();
    }
};

pub fn main() !void {
    const width = 800;
    const height = 600;
    ray.InitWindow(width, height, "Hello raylib from zig");
    defer ray.CloseWindow();
    const flags = ray.WindowFlags.FLAG_WINDOW_RESIZABLE | ray.WindowFlags.FLAG_WINDOW_TOPMOST;
    ray.SetWindowState(flags);
    ray.SetWindowMinSize(width, height);
    ray.SetTargetFPS(30);

    ray.InitAudioDevice();
    defer ray.CloseAudioDevice();

    var game_symbol = GameSymbol.new();

    while (!ray.WindowShouldClose()) {
        // const screen = Screen.new(ray.GetScreenWidth(), ray.GetScreenHeight());

        ray.BeginDrawing();
        defer ray.EndDrawing();
        if (ray.IsKeyPressed(ray.KeyCode.KEY_F5)) {
            try game_symbol.reload();
            std.log.debug("Reload Success", .{});
        }
        if (ray.IsWindowResized()) {
            game_symbol.onResize();
        }
        game_symbol.innerLoop();
    }
    game_symbol.innerCleanup();
}
