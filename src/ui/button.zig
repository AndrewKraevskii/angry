const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");
const math = @import("../math.zig");

const Vec2 = math.Vec2;

pub const ButtonConfig = struct {
    font_size: f32 = 50,
    background_color: rl.Color = rl.Color.light_gray,
    color: rl.Color = rl.Color.red,
    spacing: f32 = 2,
    padding: f32 = 4,
};

const max_test_size = 128;

const State = enum {
    nothing,
    pressed,
    hovered,
};

// TODO: when button pressed click shound be processed by the rest of the game.
pub fn button(pos: rl.Vector2, text: []const u8, config: ButtonConfig) State {
    var buffer: [max_test_size]u8 = undefined;

    const textz = std.fmt.bufPrintZ(&buffer, "{s}", .{text}) catch {
        @panic("Text is too long: expect text to be " ++ std.fmt.comptimePrint("{d}", .{max_test_size}) ++ " long");
    };
    const measured_text_size = rl.measureTextEx(rl.getFontDefault(), textz, config.font_size, config.spacing);

    const size = rlm.vector2Add(measured_text_size, rlm.vector2Scale(rlm.vector2One(), 2 * config.padding));

    rl.drawRectangleV(.{ .x = pos.x, .y = pos.y }, size, config.background_color);
    rl.drawTextEx(
        rl.getFontDefault(),
        textz,
        .{ .x = pos.x + config.padding, .y = pos.y + config.padding },
        config.font_size,
        config.spacing,
        config.color,
    );
    const normalized_cursor = rlm.vector2Subtract(rl.getMousePosition(), pos);
    if (normalized_cursor.x > 0 and normalized_cursor.y > 0 and normalized_cursor.x < size.x and normalized_cursor.y < size.y) {
        return if (rl.isMouseButtonPressed(.mouse_button_left))
            .pressed
        else
            .hovered;
    }
    return .nothing;
}
