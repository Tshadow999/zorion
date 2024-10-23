#version 330 core
layout (location = 0) in vec3 pos;
layout (location = 1) in vec2 uv;
layout (location = 2) in vec3 normal;
layout (location = 3) in vec4 color;

out vec3 o_norm;
out vec2 o_uv;

uniform mat4 u_projection;
uniform mat4 u_view;
uniform mat4 u_model;

void main() 
{
    o_norm = normal;
    o_uv = uv;

    gl_Position = u_projection * u_view * u_model * vec4(pos, 1.0);
}