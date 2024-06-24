const ApplicationState = @import("state.zig");
const ray = @import("raylib.zig");
const std = @import("std");
const ui = @import("ui/ui.zig");
const fileDialog = @import("tinyfiledialog.zig");

var innerState: ApplicationState.InnerState = undefined;
var mem: [1024 * 32]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&mem);
const allocator = fba.allocator();
var fake_spectrum = ui.fake_spectrum{ .rec = ray.Rectangle.new(0, 0, 0, 0), .bar_value = [_]f32{ 0.0, 0.6, 0.9, 0.2, 0.3 } };

export var appState: ApplicationState.StateType = ApplicationState.StateType{
    .directories = ApplicationState.directory_list{ .len = 0, .capacity = 10, .directories = undefined },
    .is_playing = false,
};

export fn getState() ApplicationState.StateType {
    std.debug.print("getting state", .{});
    return appState;
}

export fn setState(newState: ApplicationState.StateType) void {
    std.debug.print("setting state", .{});
    appState = newState;

    var i: usize = 0;
    while (i < appState.directories.len) {
        const path: [*c]u8 = &appState.directories.directories[i];
        const music = ray.LoadMusicStream(path);
        const path_zig_style: [:0]u8 = std.mem.span(path);
        const dirAndFilename = getDirAndFilename(path_zig_style);
        const dir = allocator.dupeZ(u8, dirAndFilename[0]) catch @panic("cannot allocate dir");
        const filename = allocator.dupeZ(u8, dirAndFilename[1]) catch @panic("cannot allocate filename");
        innerState.tracks.track_list.append(ApplicationState.Track{ .file_path = &appState.directories.directories[i], .music = music, .dir = dir, .name = filename }) catch @panic("Failed to append music");
        i += 1;
    }
}

export fn init() void {
    innerState.music_logo = ray.LoadImage("./assets/notes.png");
    resizeImageForNowPlaying();
    innerState.music_texture = ray.LoadTextureFromImage(innerState.music_logo);
    const shuffle_button_img = ray.LoadImage("./assets/shuffle_button.png");
    const loop_button_img = ray.LoadImage("./assets/loop_button.png");
    const start_button_img = ray.LoadImage("./assets/start_button.png");
    const pause_button_img = ray.LoadImage("./assets/pause_button.png");
    const prev_button_image = ray.LoadImage("./assets/prev_button.png");
    const next_button_image = ray.LoadImage("./assets/next_button.png");

    innerState.title_font = ray.LoadFontEx("./assets/fonts/Roboto-Medium.ttf", 20, null, 0);
    innerState.author_font = ray.LoadFontEx("./assets/fonts/Roboto-Regular.ttf", 16, null, 0);
    innerState.loop_button_texture = ray.LoadTextureFromImage(loop_button_img);
    innerState.start_button_texture = ray.LoadTextureFromImage(start_button_img);
    innerState.pause_button_texture = ray.LoadTextureFromImage(pause_button_img);
    innerState.prev_button_texture = ray.LoadTextureFromImage(prev_button_image);
    innerState.next_button_texture = ray.LoadTextureFromImage(next_button_image);
    innerState.shuffle_button_texture = ray.LoadTextureFromImage(shuffle_button_img);

    ray.UnloadImage(loop_button_img);
    ray.UnloadImage(start_button_img);
    ray.UnloadImage(pause_button_img);
    ray.UnloadImage(prev_button_image);
    ray.UnloadImage(next_button_image);
    ray.UnloadImage(shuffle_button_img);

    ui.io.init() catch @panic("Failed to init io thread");

    innerState.tracks = ApplicationState.Tracks{ .track_list = std.ArrayList(ApplicationState.Track).init(allocator), .selected_track = 0 };

    std.log.debug("Init", .{});
}

export fn cleanup() void {
    std.log.debug("Cleanup", .{});
    ui.io.postMessage(ui.io.message.done);
    innerState.tracks.track_list.deinit();

    ray.UnloadImage(innerState.music_logo);
    ray.UnloadTexture(innerState.music_texture);
    ray.UnloadTexture(innerState.start_button_texture);
    ray.UnloadTexture(innerState.prev_button_texture);
    ray.UnloadTexture(innerState.next_button_texture);
    ray.UnloadTexture(innerState.shuffle_button_texture);
    ray.UnloadFont(innerState.title_font);
    ray.UnloadFont(innerState.author_font);

    std.log.debug("Completed Cleanup", .{});
}

export fn onResize() void {
    // resizeImageForNowPlaying();
    // ray.UnloadTexture(InnerState.music_texture);
    // InnerState.music_texture = ray.LoadTextureFromImage(InnerState.music_logo);
}

fn resizeImageForNowPlaying() void {
    ray.ImageResizeNN(&innerState.music_logo, 320, 320);
}

export fn loop() void {
    const bg_color = ray.Color.newFromHex(0x121212);

    handleMessage();
    if (innerState.tracks.isPlaying()) {
        innerState.tracks.updateMusicStream();
    }

    const width = ray.GetScreenWidth();
    const height = ray.GetScreenHeight();
    const screen = Screen.new(width, height);
    const audioControlRect = ray.Rectangle.new(0, screen.heightAsFloat() - 80, screen.widthAsFloat(), 80);
    // const nowPlayingRect = ray.Rectangle.new(screen.widthAsFloat() * 0.2, screen.heightAsFloat() * 0.1, screen.widthAsFloat() * 0.6, screen.heightAsFloat() * 0.55);
    const music_list_rect = ray.Rectangle.new(0, 0, screen.widthAsFloat(), screen.heightAsFloat() - audioControlRect.height);
    ray.ClearBackground(bg_color);
    // drawMusicNowPlaying(nowPlayingRect);
    drawControlButton(audioControlRect);

    if (innerState.tracks.track_list.items.len > 0) {
        drawMusicList(music_list_rect);
    }
}

/// Returns (dir, filename)
fn getDirAndFilename(path: []u8) [2][]u8 {
    var i = path.len - 1;
    while (i > 0) {
        if (path[i] == '/') {
            break;
        }
        i -= 1;
    }
    const path_with_dir = path[0..i];
    const fileName = path[(i + 1)..(path.len)];

    i = path_with_dir.len - 1;
    var count: usize = 0;
    while (i > 0) {
        count += 1;
        if (path_with_dir[i] == '/') {
            break;
        }
        i -= 1;
    }
    const dir = path_with_dir[(i + 1)..];
    return .{ dir, fileName };
}

fn handleMessage() void {
    const res = ui.io.getResponse();

    switch (res) {
        .none => {},
        .done => {
            std.log.debug("done", .{});
        },
        .open_select_folder_for_load_music => |entry| {
            if (entry) |music_paths| {
                for (music_paths) |path| {
                    const clone_path = allocator.dupeZ(u8, path) catch @panic("cannot allocate path");
                    const music = ray.LoadMusicStream(clone_path.ptr);

                    const dirAndFilename = getDirAndFilename(clone_path);
                    const dir = allocator.dupeZ(u8, dirAndFilename[0]) catch @panic("cannot allocate dir");
                    const fileName = allocator.dupeZ(u8, dirAndFilename[1]) catch @panic("cannot allocate filename");
                    appState.directories.append(path) catch @panic("failed to append path");

                    innerState.tracks.track_list.append(.{ .file_path = clone_path, .music = music, .dir = dir, .name = fileName }) catch @panic("failed to append music");
                }
            } else {
                std.log.debug("null", .{});
            }
        },
    }
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

pub fn drawMusicList(music_list_rect: ray.Rectangle) void {
    ray.DrawRectangleRounded(music_list_rect, 0, 4, ray.Color.BLACK);
    const music_list_height = 60.0;
    const music_list_width = music_list_rect.width - 20;

    //headers
    const header_rect = ray.Rectangle.new(10, 10, music_list_width, music_list_height);
    const header_number_rect = ray.Rectangle.new(header_rect.x + 10, header_rect.y + 10, music_list_height - 20, music_list_height / 2);
    const header_number_position = ray.Vector2.new(header_number_rect.x, header_number_rect.y);
    innerState.title_font.drawText("#", header_number_position, 20, ray.Color.LIGHTGRAY);

    const header_title = ray.Rectangle.new(header_rect.x + 30, header_rect.y + 10, music_list_width - 20, music_list_height / 2);
    const header_title_position = ray.Vector2.new(header_title.x, header_title.y);
    innerState.title_font.drawText("Title", header_title_position, 20, ray.Color.LIGHTGRAY);

    var track_iter = innerState.tracks.iterator();
    var i: i32 = 1;
    var buffer = [_]u8{0} ** 128;
    var fba_local = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator_local = fba_local.allocator();

    while (track_iter.nextDir()) |dir| {
        const dir_rect = ray.Rectangle.new(10, 0 + (music_list_height * intToFloat(i)) + 20, music_list_width, music_list_height);
        const text_size = innerState.author_font.measureText(dir, 16);
        const dir_position = ray.Vector2.new(dir_rect.x + 20, dir_rect.y - 8);
        // std.debug.print("x: {d} y: {d}\n", .{ text_size.x, text_size.y });
        const first_dir_start_line = ray.Vector2.new(dir_rect.x, dir_rect.y);
        const first_dir_end_line = ray.Vector2.new(dir_rect.x + dir_position.x - 12, dir_rect.y);

        const second_dir_start_line = ray.Vector2.new(dir_position.x + text_size.x + 4, dir_rect.y);
        const second_dir_end_line = ray.Vector2.new(dir_rect.width - dir_position.x, dir_rect.y);

        innerState.author_font.drawText(dir, dir_position, 16, ray.Color.LIGHTGRAY);
        ray.DrawLineV(first_dir_start_line, first_dir_end_line, ray.Color.LIGHTGRAY);
        ray.DrawLineV(second_dir_start_line, second_dir_end_line, ray.Color.LIGHTGRAY);
        i += 1;

        var music_count: i32 = 1;
        while (track_iter.nextUntilDirectory()) |track| {
            const music_rect = ray.Rectangle.new(10, (music_list_height * intToFloat(i)), music_list_width, music_list_height);
            const current_index = track_iter.getIndex() - 1;
            const on_hover = ray.CheckCollisionPointRec(ray.GetMousePosition(), music_rect);
            const is_selected = innerState.tracks.selected_track == current_index;

            if (on_hover) {
                if (ray.IsMouseButtonReleased(ray.MouseButton.MOUSE_BUTTON_LEFT)) {
                    innerState.tracks.stopSelectedTrack();
                    innerState.tracks.changeSelectedTrack(current_index);
                    innerState.tracks.playSelectedTrack();
                    appState.is_playing = true;
                }
                ray.DrawRectangleRounded(music_rect, 0, 4, ray.Color.newFromHex(0x303030));
            }

            const number_rect = ray.Rectangle.new(music_rect.x + 10, music_rect.y + 15, music_list_height - 20, music_list_height / 2);
            const number_position = ray.Vector2.new(number_rect.x, number_rect.y);

            if (is_selected) {
                const fake_spectrum_rec = number_rect.newDepend(-5, 0, -18, 0);
                fake_spectrum.rec = fake_spectrum_rec;
                fake_spectrum.draw();
            } else if (on_hover and !is_selected) {
                //titik atas
                const v3 = ray.Vector2.new(number_rect.x, number_rect.y + 3);
                //titik tinggi
                const v2 = ray.Vector2.new(number_rect.x + 10, number_rect.y + 10.5);
                //titik bawah
                const v1 = ray.Vector2.new(number_rect.x, number_rect.y + 18);
                ray.DrawTriangle(v1, v2, v3, ray.Color.WHITE);
            } else {
                // This should never fail, seriously.
                const number = std.fmt.allocPrint(allocator_local, "{}", .{music_count}) catch unreachable;
                innerState.title_font.drawText(number, number_position, 20, ray.Color.WHITE);
                allocator_local.free(number);
            }

            const title_rect = ray.Rectangle.new(music_rect.x + 40, music_rect.y + 10, music_list_width - 20, music_list_height / 2);
            const title_position = ray.Vector2.new(title_rect.x, title_rect.y);
            const title = track.name;
            // std.debug.print("current play {} index {}\n", .{ innerState.tracks.selected_track, index });
            const text_color = if (is_selected) ray.Color.newFromHex(0x10C010) else ray.Color.WHITE;
            innerState.title_font.drawText(title, title_position, 20, text_color);

            const creator_rect = ray.Rectangle.new(music_rect.x + 40, music_rect.y + 30, music_list_width - 20, music_list_height / 2);
            const creator_position = ray.Vector2.new(creator_rect.x, creator_rect.y + 2);
            innerState.author_font.drawText("HOYO-MIX", creator_position, 16, ray.Color.LIGHTGRAY);

            music_count += 1;

            i += 1;
        }
    }
}

pub fn drawMusicNowPlaying(nowPlayingRect: ray.Rectangle) void {
    ray.DrawRectangleRounded(nowPlayingRect, 0.2, 4, ray.Color.newFromHex(0x1F1F1F));

    const musicRect = ray.Rectangle.new(0, 0, intToFloat(innerState.music_texture.width), intToFloat(innerState.music_texture.height));
    const draw_x = nowPlayingRect.x + (nowPlayingRect.width / 2.0) - 20;
    const draw_y = nowPlayingRect.y + (nowPlayingRect.height / 2.0);

    const musicDrawRect = ray.Rectangle.new(draw_x, draw_y, intToFloat(innerState.music_texture.width), intToFloat(innerState.music_texture.height));
    const musicCenter = ray.Vector2.new(intToFloat(innerState.music_texture.width) / 2.0, intToFloat(innerState.music_texture.height) / 2.0);

    ray.DrawTexturePro(innerState.music_texture, musicRect, musicDrawRect, musicCenter, 0, ray.Color.WHITE);
}

pub fn drawControlButton(audioButtonRect: ray.Rectangle) void {
    const audioButton = audioButtonRect;
    ray.DrawRectangleRec(audioButtonRect, ray.Color.newFromHex(0x1C1C1E));

    const bg_color = ray.Color.newFromHex(0x2C2C2E);
    const text_color = ray.Color.newFromHex(0xFFFFFF);
    const hover_bg_color = ray.Color.newFromHex(0x444446);
    const button_height = audioButton.height * 0.8;
    const button_y = audioButton.y + (audioButton.height / 2.0) - (button_height / 2.0);
    const button_w = 80;
    const center_x = audioButton.width / 2.0;
    const button_style = ui.button.ButtonStyle{
        .background_color = bg_color,
        .hover_bg_color = hover_bg_color,
        .text_color = text_color,
        .font_size = 20,
        .texture_height = 24,
        .texture_width = 24,
    };
    const shuffle_button_style = ui.button.ButtonStyle{
        .background_color = bg_color,
        .hover_bg_color = hover_bg_color,
        .text_color = text_color,
        .font_size = 20,
        .texture_height = 32,
        .texture_width = 48,
    };
    var open_dir_button = ui.button.new(audioButtonRect.x + 20, button_y, button_w, button_height, " ");
    open_dir_button.setStyle(button_style);
    open_dir_button.setOnClick(onClickDir);

    var shuffleButton = ui.button.newWithTexture(innerState.shuffle_button_texture, center_x - button_w - 120, button_y, button_w, button_height);
    shuffleButton.setStyle(shuffle_button_style);
    shuffleButton.setOnClick(onClickShuffle);

    var prevButton = ui.button.newWithTexture(innerState.prev_button_texture, center_x - button_w - 20, button_y, button_w, button_height);
    prevButton.setStyle(button_style);

    const play_button_texture = if (appState.is_playing) innerState.pause_button_texture else innerState.start_button_texture;
    var playButton = ui.button.newWithTexture(play_button_texture, center_x, button_y, button_w, button_height);
    playButton.setOnClick(onClickPlay);
    playButton.setStyle(button_style);

    var nextButton = ui.button.newWithTexture(innerState.next_button_texture, center_x + button_w + 20, button_y, button_w, button_height);
    nextButton.setStyle(button_style);

    var loopButton = ui.button.newWithTexture(innerState.loop_button_texture, center_x + button_w + 120, button_y, button_w, button_height);
    loopButton.setStyle(button_style);

    open_dir_button.update();
    shuffleButton.update();
    playButton.update();
    nextButton.update();
    prevButton.update();
    loopButton.update();

    open_dir_button.draw();
    shuffleButton.draw();
    playButton.draw();
    nextButton.draw();
    prevButton.draw();
    loopButton.draw();
}
fn onClickDir() void {
    ui.io.postMessage(ui.io.message.open_select_folder_for_load_music);
}

fn onClickPlay() void {
    if (innerState.tracks.isPlaying()) {
        innerState.tracks.pausePlaying();
        appState.is_playing = false;
    } else {
        innerState.tracks.continuePlaying();
        appState.is_playing = true;
    }
}

fn onClickShuffle() void {
    std.debug.print("Shuffle\n", .{});
}
