#version 330 core
layout (location = 0) in vec3 a_pos;
layout (location = 1) in vec2 a_uv;
layout (location = 2) in vec3 a_normal;
layout (location = 3) in vec4 a_color;

out vec3 o_norm;
out vec2 o_uv;
out vec4 o_color;

uniform mat4 u_projection;
uniform mat4 u_view;
uniform mat4 u_model;

void main() 
{
    o_uv = a_uv;
    o_norm = a_normal;
    o_color = a_color;

    gl_Position = u_projection * u_view * (u_model * vec4(a_pos, 1.0));
}