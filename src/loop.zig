const ApplicationState = @import("state.zig");
const ray = @import("raylib.zig");
const std = @import("std");
const ui = @import("ui/ui.zig");

var InnerState: ApplicationState.InnerState = undefined;
/// Button States. it will not be preserved each hot reloaded.
var button_states: ApplicationState.ButtonStateList = undefined;
var mem: [4089]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&mem);
const allocator = fba.allocator();

export var state = ApplicationState.StateType{
    .foo = 0,
};

export fn getState() ApplicationState.StateType {
    return state;
}

export fn setState(newState: ApplicationState.StateType) void {
    state = newState;
}

export fn init() void {
    button_states = ApplicationState.ButtonStateList.init(allocator);

    InnerState.music_logo = ray.LoadImage("./assets/notes.png");
    resizeImageForNowPlaying();
    InnerState.music_texture = ray.LoadTextureFromImage(InnerState.music_logo);
    const start_button_img = ray.LoadImage("./assets/start_button.png");
    InnerState.start_button_texture = ray.LoadTextureFromImage(start_button_img);
    ray.UnloadImage(start_button_img);
    std.log.debug("Init", .{});
}

export fn cleanup() void {
    ray.UnloadTexture(InnerState.music_texture);
    ray.UnloadImage(InnerState.music_logo);
    ray.UnloadTexture(InnerState.start_button_texture);
}

export fn onResize() void {
    // resizeImageForNowPlaying();
    // ray.UnloadTexture(InnerState.music_texture);
    // InnerState.music_texture = ray.LoadTextureFromImage(InnerState.music_logo);
}

fn resizeImageForNowPlaying() void {
    ray.ImageResizeNN(&InnerState.music_logo, 320, 320);
}

export fn loop() void {
    const bg_color = ray.Color.newFromHex(0x121212);

    const width = ray.GetScreenWidth();
    const height = ray.GetScreenHeight();
    const screen = Screen.new(width, height);
    const audioControlRect = ray.Rectangle.new(0, screen.heightAsFloat() - 80, screen.widthAsFloat(), 80);
    const nowPlayingRect = ray.Rectangle.new(screen.widthAsFloat() * 0.2, screen.heightAsFloat() * 0.1, screen.widthAsFloat() * 0.6, screen.heightAsFloat() * 0.55);
    ray.ClearBackground(bg_color);
    drawMusicNowPlaying(nowPlayingRect);
    drawControlButton(audioControlRect);
}

const Screen = struct {
    width: c_int,
    height: c_int,

    pub fn new(width: c_int, height: c_int) Screen {
        return Screen{ .width = width, .height = height };
    }

    pub inline fn widthAsFloat(self: Screen) f32 {
        return @as(f32, @floatFromInt(self.width));
    }

    pub inline fn heightAsFloat(self: Screen) f32 {
        return @as(f32, @floatFromInt(self.height));
    }
};

fn floatToInt(in: f32) i32 {
    return @as(i32, @intFromFloat(in));
}

fn intToFloat(in: i32) f32 {
    return @as(f32, @floatFromInt(in));
}

pub fn drawMusicNowPlaying(nowPlayingRect: ray.Rectangle) void {
    ray.DrawRectangleRounded(nowPlayingRect, 0.2, 4, ray.Color.newFromHex(0x1F1F1F));

    const musicRect = ray.Rectangle.new(0, 0, intToFloat(InnerState.music_texture.width), intToFloat(InnerState.music_texture.height));
    const draw_x = nowPlayingRect.x + (nowPlayingRect.width / 2.0) - 20;
    const draw_y = nowPlayingRect.y + (nowPlayingRect.height / 2.0);

    const musicDrawRect = ray.Rectangle.new(draw_x, draw_y, intToFloat(InnerState.music_texture.width), intToFloat(InnerState.music_texture.height));
    const musicCenter = ray.Vector2.new(intToFloat(InnerState.music_texture.width) / 2.0, intToFloat(InnerState.music_texture.height) / 2.0);

    ray.DrawTexturePro(InnerState.music_texture, musicRect, musicDrawRect, musicCenter, 0, ray.Color.WHITE);
}

pub fn drawControlButton(audioButtonRect: ray.Rectangle) void {
    const audioButton = audioButtonRect;
    ray.DrawRectangleRec(audioButtonRect, ray.Color.newFromHex(0x1C1C1E));

    const bg_color = ray.Color.newFromHex(0x2C2C2E);
    const text_color = ray.Color.newFromHex(0xFFFFFF);
    const hover_bg_color = ray.Color.newFromHex(0x444446);
    const button_height = audioButton.height * 0.8;
    const button_y = audioButton.y + (audioButton.height / 2.0) - (button_height / 2.0);
    const center_x = audioButton.width / 2.0;
    const button_style = ui.button.ButtonStyle{
        .background_color = bg_color,
        .hover_bg_color = hover_bg_color,
        .text_color = text_color,
        .font_size = 20,
        .texture_height = 24,
        .texture_width = 24,
    };

    var playButton = ui.button.newWithTexture(InnerState.start_button_texture, center_x - 200, button_y, 50, button_height);
    playButton.setOnClick(onClickPlay);
    playButton.setStyle(button_style);

    var pauseButton = ui.button.new(center_x - 100, button_y, 50, button_height, "Pause");
    pauseButton.setStyle(button_style);
    pauseButton.setOnClick(onClickPause);

    var stopButton = ui.button.new(center_x, button_y, 50, button_height, "Stop");
    stopButton.setStyle(button_style);
    stopButton.setOnClick(onClickPause);

    var nextButton = ui.button.new(center_x + 100, button_y, 50, button_height, "Next");
    nextButton.setStyle(button_style);

    var prevButton = ui.button.new(center_x + 200, button_y, 50, button_height, "Prev");
    prevButton.setStyle(button_style);

    playButton.update();
    pauseButton.update();
    stopButton.update();
    nextButton.update();
    prevButton.update();

    playButton.draw();
    pauseButton.draw();
    stopButton.draw();
    nextButton.draw();
    prevButton.draw();
}

fn onClickPlay() void {
    std.debug.print("Play\n", .{});
}

fn onClickPause() void {
    std.debug.print("Pause\n", .{});
}
