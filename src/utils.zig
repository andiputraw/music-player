fn floatToInt(in: f32) i32 {
    return @as(i32, @intFromFloat(in));
}

fn intToFloat(in: i32) f32 {
    return @as(f32, @floatFromInt(in));
}
