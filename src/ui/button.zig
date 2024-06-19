const ray = @import("../raylib.zig");
const std = @import("std");
const state = @import("../state.zig");

pub fn new(x: f32, y: f32, width: f32, height: f32, text: []const u8) Button {
    return Button{
        .rect = ray.Rectangle.new(x, y, width, height),
        .text = text,
        .style = ButtonStyle{},
    };
}

pub fn newWithTexture(texture: ray.Texture, x: f32, y: f32, width: f32, height: f32) Button {
    return Button{
        .rect = ray.Rectangle.new(x, y, width, height),
        .text = "",
        .style = ButtonStyle{ .background_color = ray.Color.DARKGRAY, .text_color = ray.Color.LIGHTGRAY, .font_size = 20, .hover_bg_color = ray.Color.DARKGRAY },
        .texture = texture,
    };
}

pub const ButtonStyle = struct {
    background_color: ray.Color = ray.Color.DARKGRAY,
    hover_bg_color: ray.Color = ray.Color.DARKGRAY,
    text_color: ray.Color = ray.Color.BLACK,
    font_size: i32 = 20,
    texture_width: f32 = 0,
    texture_height: f32 = 0,
};

/// Button Component
pub const Button = struct {
    rect: ray.Rectangle,
    /// Text to display, ignored if texture is set
    text: []const u8,
    style: ButtonStyle,
    /// Texture to render
    texture: ?ray.Texture = null,
    onClick: ?(*const fn () void) = null,

    pub fn update(self: *Button) void {
        if (ray.CheckCollisionPointRec(ray.GetMousePosition(), self.rect)) {
            if (ray.IsMouseButtonPressed(ray.MouseButton.MOUSE_BUTTON_LEFT)) {
                self.on_clicked = true;
                std.log.debug("MOUSE LEFT PRESSED, Is clicked {}", .{self.on_clicked});
            }

            if (ray.IsMouseButtonReleased(ray.MouseButton.MOUSE_BUTTON_LEFT)) {
                std.log.debug("MOUSE LEFT RELEASE, Is clicked {}", .{self.on_clicked});
                if (self.onClick) |callback| {
                    callback();
                }
            }
        } else {
            self.on_clicked = false;
        }
    }

    pub fn setOnClick(self: *Button, callback: fn () void) void {
        self.onClick = callback;
    }

    pub fn draw(self: Button) void {
        var bg_color = self.style.background_color;
        if (ray.CheckCollisionPointRec(ray.GetMousePosition(), self.rect)) {
            bg_color = self.style.hover_bg_color;
        }

        ray.DrawRectangleRounded(self.rect, 0.2, 4, bg_color);
        const text_length: f32 = @floatFromInt(ray.MeasureText(self.text.ptr, self.style.font_size));
        if (self.texture) |texture| {
            const texture_source = ray.Rectangle.new(0, 0, @floatFromInt(texture.width), @floatFromInt(texture.height));
            const draw_x = self.rect.x + (self.rect.width / 2.0);
            const draw_y = self.rect.y + (self.rect.height / 2.0);
            const texture_destination = ray.Rectangle.new(draw_x, draw_y, self.style.texture_width, self.style.texture_height);
            const texture_center = ray.Vector2.new(self.style.texture_width / 2.0, self.style.texture_height / 2.0);

            ray.DrawTexturePro(texture, texture_source, texture_destination, texture_center, 0, ray.Color.WHITE);
        } else {
            ray.DrawText(self.text.ptr, @intFromFloat(self.rect.x + (self.rect.width / 2.0) - (text_length / 2.0)), @intFromFloat((self.rect.y + self.rect.height / 2.0) - 5), self.style.font_size, self.style.text_color);
        }
    }

    pub fn setStyle(self: *Button, style: ButtonStyle) void {
        self.style = style;
    }
};
