const box2d = @import("box2d.zig");

box2d: box2d.Body,

pub fn draw(self: @This()) void {
    var shape: [1]box2d.Shape = undefined;
    self.box2d.getShapes(&shape);

    if (shape[0].getType() == .polygon_shape) {
        shape[0].get;
    }
}
