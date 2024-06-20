const ray = @import("./raylib.zig");
const std = @import("std");

pub const ButtonState = struct {
    id: i32 = 0,
    is_onclicked: bool = false,
};

pub const ButtonStateList = std.ArrayList(ButtonState);

pub const StateType = extern struct { is_playing: bool };
pub const InnerState = struct {
    music_logo: ray.Image,
    music_texture: ray.Texture,
    start_button_texture: ray.Texture,
    pause_button_texture: ray.Texture,
    prev_button_texture: ray.Texture,
    next_button_texture: ray.Texture,
    loop_button_texture: ray.Texture,
    shuffle_button_texture: ray.Texture,
};
