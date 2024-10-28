const std = @import("std");

const math = @import("math");
const gl = @import("gl");

const c = @import("../c.zig");
const Color = @import("../color.zig");

pub const Scene = struct {
    objects: std.BoundedArray(Object, 10240),

    pub fn render(self: *Scene) !void {
        for (self.objects.constSlice()) |object| {
            try object.render();
        }
    }

    pub fn addObject(self: *Scene, mesh: *Mesh, material: *Material) !*Object {
        const object = try self.objects.addOne();
        object.* = .{ .mesh = mesh, .material = material };
        return object;
    }
};

pub const Transform = struct {
    local2World: math.Mat4x4 = math.Mat4x4.ident,
};

pub const Object = struct {
    transform: Transform = .{},
    mesh: ?*Mesh = null,
    material: ?*Material = null,
    visible: bool = true,

    pub fn render(self: *const Object) !void {
        if (!self.visible) return;
        const mesh = self.mesh orelse return;
        const material = self.material orelse return;
        try material.bind();
        try material.shader.?.setUniformByName("u_model", self.transform.local2World);
        mesh.bind();
    }
};

pub const Vertex = extern struct {
    position: math.Vec3 = math.vec3(0, 0, 0),
    uv: math.Vec2 = math.vec2(0, 0),
    normal: math.Vec3 = math.vec3(0, 0, 0),
    color: math.Vec4 = math.vec4(0, 0, 0, 0),

    pub fn addAtributes() void {
        Mesh.addElement(0, 3, 0, false); // @offsetOf(Vertex, "position") = 0
        Mesh.addElement(1, 2, @offsetOf(Vertex, "uv"), false);
        Mesh.addElement(2, 3, @offsetOf(Vertex, "normal"), false);
        Mesh.addElement(3, 4, @offsetOf(Vertex, "color"), false);
    }
};

pub const Material = struct {
    shader: ?*Shader = null,
    properties: std.BoundedArray(Property, 16) = .{},

    pub const Property = struct {
        name: [:0]const u8,
        data: Data,

        const Data = union(enum) {
            int: i32,
            float: i32,
            texture: *Texture,
            vec2: math.Vec2,
            vec3: math.Vec3,
            vec4: math.Vec4,
            mat4: math.Mat4x4,
            color: Color,
        };
    };

    pub fn bind(self: Material) !void {
        if (self.shader) |shader| {
            shader.bind();

            var textureUnit: i32 = 1;

            for (self.properties.constSlice()) |prop| {
                switch (prop.data) {
                    .texture => |texture| {
                        texture.bind(textureUnit);
                        try shader.setUniformByName(prop.name, textureUnit);
                        textureUnit += 1;
                    },
                    .color => |color| try shader.setUniformByName(prop.name, color.toVec4()),
                    inline else => |data| {
                        try shader.setUniformByName(prop.name, data);
                    },
                }
            }
        }
    }

    pub fn addProperty(self: *Material, name: [:0]const u8, value: anytype) !void {
        inline for (std.meta.fields(Property.Data)) |field| {
            if (field.type == @TypeOf(value)) {
                try self.properties.append(.{
                    .name = name,
                    .data = @unionInit(Material.Property.Data, field.name, value),
                });
                return;
            }
        }

        @compileError(@typeName(@TypeOf(value)) ++ " is an invalid property type!");
    }
};

pub const Mesh = struct {
    vertices: std.ArrayList(Vertex),
    indices: std.ArrayList(u32),

    vao: u32 = undefined,
    vbo: u32 = undefined,
    ibo: u32 = undefined,

    pub fn init(allocator: std.mem.Allocator) Mesh {
        return .{
            .vertices = std.ArrayList(Vertex).init(allocator),
            .indices = std.ArrayList(u32).init(allocator),
        };
    }

    fn addElement(index: u32, elementCount: i32, elementPosition: u32, normalized: bool) void {
        const glNormalized: gl.GLboolean = if (normalized) gl.TRUE else gl.FALSE;
        gl.vertexAttribPointer(
            index,
            elementCount,
            gl.FLOAT,
            glNormalized,
            @sizeOf(Vertex),
            @ptrFromInt(elementPosition),
        );
        gl.enableVertexAttribArray(index);
    }

    pub fn create(self: *Mesh) void {
        gl.genVertexArrays(1, &self.vao);
        gl.genBuffers(1, &self.vbo);
        gl.genBuffers(1, &self.ibo);

        gl.bindVertexArray(self.vao);

        gl.bindBuffer(gl.ARRAY_BUFFER, self.vbo);
        gl.bufferData(gl.ARRAY_BUFFER, @intCast(self.vertices.items.len * @sizeOf(Vertex)), self.vertices.items[0..].ptr, gl.STATIC_DRAW);

        Vertex.addAtributes();

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ibo);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @intCast(self.indices.items.len * @sizeOf(u32)), self.indices.items[0..].ptr, gl.STATIC_DRAW);

        gl.bindVertexArray(0);
        gl.bindBuffer(gl.ARRAY_BUFFER, 0);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    }

    pub fn bind(self: *Mesh) void {
        gl.bindVertexArray(self.vao);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ibo);

        gl.drawElements(gl.TRIANGLES, @intCast(self.indices.items.len), gl.UNSIGNED_INT, null);
    }

    pub fn deinit(self: *Mesh) void {
        gl.deleteVertexArrays(1, &self.vao);
        gl.deleteBuffers(1, &self.vbo);
        gl.deleteBuffers(1, &self.ibo);

        self.vertices.deinit();
        self.indices.deinit();
    }
};

pub const Shader = struct {
    program: u32 = 0,
    vertexSource: []const u8,
    fragmentSource: []const u8,

    const Error = error{
        InvalidUniformName,
        InvalidVertexShader,
        InvalidFragmentShader,
        FailedToLink,
    };

    pub fn load(self: *Shader, vertexPath: []u8, fragmentPath: []u8) void {
        _ = self;
        _ = vertexPath;
        _ = fragmentPath;
    }

    pub fn bind(self: *Shader) void {
        gl.useProgram(self.program);
    }

    pub fn compile(self: *Shader) !void {
        const vertShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertShader, 1, &self.vertexSource.ptr, null);
        gl.compileShader(vertShader);
        try checkShaderCompileStatus(vertShader, true);

        const fragShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragShader, 1, &self.fragmentSource.ptr, null);
        gl.compileShader(fragShader);
        try checkShaderCompileStatus(fragShader, false);

        self.program = gl.createProgram();
        gl.attachShader(self.program, vertShader);
        gl.attachShader(self.program, fragShader);

        gl.linkProgram(self.program);
        try checkShaderLinkStatus(self.program);

        gl.detachShader(self.program, vertShader);
        gl.detachShader(self.program, fragShader);
        gl.deleteShader(vertShader);
        gl.deleteShader(fragShader);
    }

    fn checkShaderCompileStatus(shader: u32, isVertexShader: bool) !void {
        var isCompiled: i32 = 0;
        gl.getShaderiv(shader, gl.COMPILE_STATUS, &isCompiled);
        if (isCompiled == gl.FALSE) {
            var maxLength: i32 = 0;
            gl.getShaderiv(shader, gl.INFO_LOG_LENGTH, &maxLength);

            const errorLogSize: usize = 512;
            var log = [1:0]u8{0} ** errorLogSize;
            gl.getShaderInfoLog(shader, errorLogSize, &maxLength, &log);

            gl.deleteShader(shader);

            if (isVertexShader) {
                std.log.err("VERTEX SHADER\n{s}", .{log[0..@intCast(maxLength)]});
                return Error.InvalidVertexShader;
            } else {
                std.log.err("FRAGMENT SHADER\n{s}", .{log[0..@intCast(maxLength)]});
                return Error.InvalidFragmentShader;
            }
        }
    }
    fn checkShaderLinkStatus(program: u32) !void {
        var isLinked: i32 = 0;
        gl.getProgramiv(program, gl.LINK_STATUS, &isLinked);
        if (isLinked == gl.FALSE) {
            var maxLength: i32 = 0;
            gl.getProgramiv(program, gl.INFO_LOG_LENGTH, &maxLength);

            const errorLogSize: usize = 512;
            var log = [1:0]u8{0} ** errorLogSize;
            gl.getShaderInfoLog(program, errorLogSize, &maxLength, &log);

            gl.deleteProgram(program);

            std.log.err("LINKING\n{s}", .{log[0..@intCast(maxLength)]});
            return Error.FailedToLink;
        }
    }

    pub fn deinit(self: *Shader) void {
        gl.deleteProgram(self.program);
    }

    pub fn setUniformByName(self: *Shader, name: []const u8, uniform: anytype) !void {
        const location = gl.getUniformLocation(self.program, name.ptr);
        if (location == -1) {
            std.log.err("Invalid name: {s}", .{name});
            return Error.InvalidUniformName;
        }
        setUniform(location, uniform);
    }

    // TODO add more types
    fn setUniform(location: i32, uniform: anytype) void {
        const T = @TypeOf(uniform);
        switch (T) {
            i32 => gl.uniform1i(location, uniform),
            u32 => gl.uniform1ui(location, uniform),
            f32 => gl.uniform1f(location, uniform),
            math.Vec2 => gl.uniform2fv(location, 1, &uniform.v[0]),
            math.Vec3 => gl.uniform3fv(location, 1, &uniform.v[0]),
            math.Vec4 => gl.uniform4fv(location, 1, &uniform.v[0]),
            math.Mat4x4 => gl.uniformMatrix4fv(@intCast(location), 1, gl.FALSE, &uniform.v[0].v[0]),
            else => @compileError("Uniform type not yet implemented: (" ++ @typeName(T) ++ ")!"),
        }
    }
};

pub const Texture = struct {
    width: i32 = 0,
    height: i32 = 0,
    channels: i32 = 0,
    id: u32 = 0,

    buffer: [*c]u8 = null,

    const targetChannels = 4;

    const Error = error{
        InvalidPath,
        FailedLoading,
    };

    pub fn load(path: [:0]const u8) !Texture {
        var w: c_int = undefined;
        var h: c_int = undefined;
        var channels: c_int = undefined;

        c.stbi_set_flip_vertically_on_load(1);
        const buffer = c.stbi_load(path, &w, &h, &channels, targetChannels);

        if (buffer == null) {
            return Error.FailedLoading;
        }

        return Texture{
            .width = w,
            .height = h,
            .channels = channels,
            .buffer = buffer,
        };
    }

    pub fn create(self: *Texture) void {
        gl.genTextures(1, &self.id);
        gl.bindTexture(gl.TEXTURE_2D, self.id);

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);

        // The current setup seems to work fine?
        // const internalFormat: u32 = if (self.channels == 4) gl.RGBA8 else gl.RGB8;
        // const format: u32 = if (self.channels == 4) gl.RGBA else gl.RGB;

        gl.texImage2D(
            gl.TEXTURE_2D,
            0,
            gl.RGBA8, // @intCast(internalFormat),
            self.width,
            self.height,
            0,
            gl.RGBA, // @intCast(format),
            gl.UNSIGNED_BYTE,
            self.buffer,
        );
    }

    pub fn bind(self: *Texture, slot: i32) void {
        gl.activeTexture(gl.TEXTURE0 + @as(c_uint, @intCast(slot)));
        gl.bindTexture(gl.TEXTURE_2D, self.id);
    }

    pub fn log(self: Texture) void {
        std.log.info("width:{} height:{} channels:{}", .{ self.width, self.height, self.channels });
    }

    pub fn deinit(self: *Texture) void {
        c.stbi_image_free(self.buffer);
    }
};
