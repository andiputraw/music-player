const ray = @import("./raylib.zig");
const std = @import("std");

pub const ButtonState = struct {
    id: i32 = 0,
    is_onclicked: bool = false,
};

pub const ButtonStateList = std.ArrayList(ButtonState);

pub const Track = struct {
    file_path: []u8,
    music: ray.Music,
};

pub const directory_list = extern struct {
    directories: [10][256]u8,
    len: usize = 0,
    capacity: i32 = 10,

    pub fn append(self: *directory_list, path: []const u8) !void {
        std.debug.print("len {} cap {} {}", .{ self.len, self.capacity, self.len >= self.capacity });
        if (self.len >= self.capacity) {
            return error.OutOfMemory;
        }

        std.mem.copyForwards(u8, &self.directories[self.len], path);
        self.len += 1;
    }
};

pub const Tracks = struct {
    track_list: std.ArrayList(Track),
    selected_track: usize = 0,

    pub fn isPlaying(self: Tracks) bool {
        if (self.selected_track >= self.track_list.items.len) return false;
        return ray.IsMusicStreamPlaying(self.track_list.items[self.selected_track].music);
    }

    pub fn continuePlaying(self: *Tracks) void {
        ray.ResumeMusicStream(self.track_list.items[self.selected_track].music);
    }

    pub fn pausePlaying(self: *Tracks) void {
        ray.PauseMusicStream(self.track_list.items[self.selected_track].music);
    }

    pub fn updateMusicStream(self: *Tracks) void {
        ray.UpdateMusicStream(self.track_list.items[self.selected_track].music);
    }

    pub fn playSelectedTrack(self: *Tracks) void {
        ray.PlayMusicStream(self.track_list.items[self.selected_track].music);
    }
};

pub const StateType = extern struct { is_playing: bool, directories: directory_list };
pub const InnerState = struct {
    music_logo: ray.Image,
    music_texture: ray.Texture,

    start_button_texture: ray.Texture,
    pause_button_texture: ray.Texture,
    prev_button_texture: ray.Texture,
    next_button_texture: ray.Texture,
    loop_button_texture: ray.Texture,
    shuffle_button_texture: ray.Texture,

    tracks: Tracks,
};
