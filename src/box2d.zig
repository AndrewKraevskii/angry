const std = @import("std");
pub const DebugDraw = @import("debug_draw.zig").DebugDraw;
pub const c = @cImport({
    @cInclude("box2d/box2d.h");
});

pub const World = struct {
    id: c.b2WorldId,

    pub fn create(def: *c.b2WorldDef) World {
        const id = c.b2CreateWorld(def);
        return .{
            .id = id,
        };
    }

    pub fn defaultDef() c.b2WorldDef {
        return c.b2DefaultWorldDef();
    }

    pub fn destroy(self: *World) void {
        c.b2DestroyWorld(self.id);
    }

    pub fn step(self: World, timeStep: f32, subStepCount: i32) void {
        c.b2World_Step(self.id, timeStep, subStepCount);
    }

    pub fn draw(self: World, debugDraw: *DebugDraw) void {
        c.b2World_Draw(self.id, @ptrCast(debugDraw));
    }

    pub fn createBody(self: World, def: *c.b2BodyDef) Body {
        return .{
            .id = c.b2CreateBody(self.id, def),
        };
    }

    pub fn enableSleeping(self: World, flag: bool) void {
        c.b2World_EnableSleeping(self.id, flag);
    }

    pub fn enableWarmStarting(self: World, flag: bool) void {
        c.b2World_EnableWarmStarting(self.id, flag);
    }

    pub fn enableContinuous(self: World, flag: bool) void {
        c.b2World_EnableContinuous(self.id, flag);
    }

    pub fn setResitutionThreshold(self: World, value: f32) void {
        c.b2World_SetRestitutionThreshold(self.id, value);
    }

    pub fn setContactTuning(self: World, hertz: f32, dampingRatio: f32, pushVelocity: f32) void {
        c.b2World_SetContactTuning(self.id, hertz, dampingRatio, pushVelocity);
    }

    pub fn getProfile(self: World) c.struct_b2Profile {
        return c.b2World_GetProfile(self.id);
    }
};

pub const Body = struct {
    id: c.b2BodyId,

    pub fn destroy(self: *Body) void {
        c.b2DestroyBody(self.id);
    }

    pub fn defaultDef() c.b2BodyDef {
        return c.b2DefaultBodyDef();
    }

    pub fn getPosition(self: Body) c.b2Vec2 {
        return c.b2Body_GetPosition(self.id);
    }

    pub fn getAngle(self: Body) f32 {
        return c.b2Body_GetAngle(self.id);
    }

    pub fn setTransform(self: Body, position: c.b2Vec2, angle: f32) void {
        c.b2Body_SetTransform(self.id, position, angle);
    }

    pub fn getLocalPoint(self: Body, globalPoint: c.b2Vec2) c.b2Vec2 {
        return c.b2Body_GetLocalPoint(self.id, globalPoint);
    }

    pub fn getWorldPoint(self: Body, globalPoint: c.b2Vec2) c.b2Vec2 {
        return c.b2Body_GetWorldPoint(self.id, globalPoint);
    }

    pub fn getLinearVelocity(self: Body) c.b2Vec2 {
        return c.b2Body_GetLinearVelocity(self.id);
    }

    pub fn getAngularVelocity(self: Body) f32 {
        return c.b2Body_GetAngularVelocity(self.id);
    }

    pub fn setLinearVelocity(self: Body, linearVelocity: c.b2Vec2) void {
        c.b2Body_SetLinearVelocity(self.id, linearVelocity);
    }

    pub fn setAngularVelocity(self: Body, angularVelocity: f32) void {
        c.b2Body_SetAngularVelocity(self.id, angularVelocity);
    }

    pub fn getType(self: Body) Type {
        return @enumFromInt(c.b2Body_GetType(self.id));
    }

    pub fn setType(self: Body, type_: Type) void {
        c.b2Body_SetType(self.id, @intFromEnum(type_));
    }

    pub fn getMass(self: Body) f32 {
        return c.b2Body_GetMass(self.id);
    }

    pub fn getInertiaTensor(self: Body) f32 {
        return c.b2Body_GetInertiaTensor(self.id);
    }

    pub fn getLocalCenterOfMass(self: Body) c.b2Vec2 {
        return c.b2Body_GetLocalCenterOfMass(self.id);
    }

    pub fn getWorldCenterOfMass(self: Body) c.b2Vec2 {
        return c.b2Body_GetWorldCenterOfMass(self.id);
    }

    pub fn getShapes(self: Body, shapes: []Shape) usize {
        return @intCast(c.b2Body_GetShapes(self.id, @ptrCast(shapes.ptr), @intCast(shapes.len)));
    }

    pub fn isAwake(self: Body) bool {
        return c.b2Body_IsAwake(self.id);
    }

    pub fn isEnabled(self: Body) bool {
        return c.b2Body_IsEnabled(self.id);
    }

    pub fn disable(self: Body) void {
        c.b2Body_Disable(self.id);
    }

    pub fn enable(self: Body) void {
        c.b2Body_Enable(self.id);
    }

    pub fn createCircle(self: Body, def: c.b2ShapeDef, circle: c.b2Circle) Shape {
        return .{
            .id = c.b2CreateCircleShape(self.id, &def, &circle),
        };
    }

    pub fn createPolygon(self: Body, def: *c.b2ShapeDef, polygon: Polygon) Shape {
        return .{
            .id = c.b2CreatePolygonShape(self.id, def, &polygon.polygon),
        };
    }
};

pub const Shape = struct {
    id: c.b2ShapeId,

    pub const ShapeType = enum(u32) {
        circle_shape = 0,
        capsule_shape = 1,
        segment_shape = 2,
        polygon_shape = 3,
        smooth_segment_shape = 4,
    };

    pub fn defaultDef() c.b2ShapeDef {
        return c.b2DefaultShapeDef();
    }

    pub fn getBody(self: Shape) Body {
        return .{
            .id = c.b2Shape_GetBody(self.id),
        };
    }

    pub fn testPoint(self: Shape, point: c.b2Vec2) bool {
        return c.b2Shape_TestPoint(self.id, point);
    }

    pub fn setFriction(self: Shape, friction: f32) void {
        c.b2Shape_SetFriction(self.id, friction);
    }

    pub fn getType(self: Shape) ShapeType {
        return @enumFromInt(c.b2Shape_GetType(self.id));
    }

    pub fn getPolygon(self: Shape) Polygon {
        return .{ .polygon = c.b2Shape_GetPolygon(self.id) };
    }
};

pub const Polygon = struct {
    polygon: c.b2Polygon,

    pub fn makeBox(hx: f32, hy: f32) Polygon {
        return .{
            .polygon = c.b2MakeBox(hx, hy),
        };
    }
};

pub const Type = enum(u32) {
    static_body = 0,
    kinematic_body = 1,
    dynamic_body = 2,
};

test World {
    var worldDef = World.defaultDef();
    worldDef.gravity = .{ .x = 0.0, .y = -10.0 };
    var world = World.create(&worldDef);

    var groundBodyDef = Body.defaultDef();
    groundBodyDef.position = .{ .x = 0.0, .y = -10.0 };

    var groundBody = world.createBody(&groundBodyDef);

    const groundBox = Polygon.makeBox(50.0, 10.0);
    var groundShapeDef = Shape.defaultDef();

    _ = groundBody.createPolygon(&groundShapeDef, groundBox);

    var bodyDef = Body.defaultDef();
    bodyDef.type = c.b2_dynamicBody;
    bodyDef.position = .{ .x = 0.0, .y = 4.0 };

    var body = world.createBody(&bodyDef);

    const dynamicBox = Polygon.makeBox(1.0, 1.0);

    var shapeDef = Shape.defaultDef();

    shapeDef.density = 1.0;
    shapeDef.friction = 0.3;

    _ = body.createPolygon(&shapeDef, dynamicBox);

    for (0..60) |_| {
        const timeStep = 1.0 / 60.0;
        const velocityIterations = 6;

        world.step(timeStep, velocityIterations);
    }

    const position = body.getPosition();
    const angle = body.getAngle();

    try std.testing.expect(@abs(position.x) < 0.01);
    try std.testing.expect(@abs(position.y - 1.0) < 0.01);
    try std.testing.expect(@abs(angle) < 0.01);

    world.destroy();
}
