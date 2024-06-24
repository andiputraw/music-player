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
    dir: []u8,
    name: []u8,
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

pub const TracksIterator = struct {
    tracks: *Tracks,
    index: usize = 0,
    dir: []u8,
    /// Return the directory of current iterator.
    /// Return null if iterator ends.
    pub fn nextDir(self: *TracksIterator) ?[]u8 {
        if (self.index >= self.tracks.track_list.items.len) return null;
        return self.dir;
    }
    /// Return the next track of current iterator.
    /// Iterator ends on the next directory.
    /// Check {dir} to see if iterator ends.
    pub fn nextUntilDirectory(self: *TracksIterator) ?Track {
        if (self.index >= self.tracks.track_list.items.len) return null;

        const track = self.tracks.track_list.items[self.index];
        if (std.mem.eql(u8, track.dir, self.dir)) {
            self.index += 1;
            return track;
        }
        self.dir = track.dir;
        return null;
    }
    /// Return the index of current iterator.
    /// to get the index of last iterator, subtract with 1.
    pub fn getIndex(self: *TracksIterator) usize {
        return self.index;
    }
};

pub const Tracks = struct {
    track_list: std.ArrayList(Track),
    selected_track: usize = 0,

    pub fn iterator(self: *Tracks) TracksIterator {
        return TracksIterator{ .tracks = self, .dir = self.track_list.items[0].dir };
    }

    pub fn changeSelectedTrack(self: *Tracks, index: usize) void {
        self.selected_track = index;
    }

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

    pub fn stopSelectedTrack(self: *Tracks) void {
        ray.StopMusicStream(self.track_list.items[self.selected_track].music);
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
    title_font: ray.Font,
    author_font: ray.Font,
};
