const ray = @import("./raylib.zig");
const std = @import("std");

pub const ButtonState = struct {
    id: i32 = 0,
    is_onclicked: bool = false,
};

pub const ButtonStateList = std.ArrayList(ButtonState);

pub const StateType = extern struct { foo: i32 };
pub const InnerState = struct {
    music_logo: ray.Image,
    music_texture: ray.Texture,
    start_button_texture: ray.Texture,
};
