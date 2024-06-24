pub const ray = @import("../raylib.zig");
pub const button = @import("./button.zig");
pub const io = @import("./io.zig");
pub const std = @import("std");
pub const fake_spectrum = struct {
    rec: ray.Rectangle,
    //each bar value. Should be between 0 and 1
    bar_value: [5]f32,
    bar_direction: [5]f32 = [_]f32{ 1, 1, 1, 1, 1 },
    bar_speed: [5]f32 = [_]f32{ 0.12, 0.09, 0.11, 0.11, 0.12 },

    const bar_count = 5.0;
    pub fn draw(self: *fake_spectrum) void {
        const bar_width = self.rec.width / bar_count;

        for (0..bar_count) |i| {
            const position = self.bar_value[i];
            const direction = self.bar_direction[i];

            self.bar_value[i] = position + (direction * self.bar_speed[i]);

            if (position > 1.00) {
                self.bar_value[i] = 1.0;
                self.bar_direction[i] = -1;
            } else if (position < 0.00) {
                self.bar_value[i] = 0.0;
                self.bar_direction[i] = 1;
            }

            const x = self.rec.x + @as(f32, @floatFromInt(i)) * bar_width;
            const h: f32 = self.rec.height * position;
            const bar_rect = ray.Rectangle.new(x, self.rec.y + h, bar_width, self.rec.height - h);
            ray.DrawRectangleRec(bar_rect, ray.Color.newFromHex(0x2CCC2C));
        }
    }
};
