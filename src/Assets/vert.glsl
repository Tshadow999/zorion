#version 330 core
layout (location = 0) in vec3 pos;
layout (location = 1) in vec2 uv;
layout (location = 2) in vec3 normal;
layout (location = 3) in vec4 color;

out vec3 norm;

uniform vec3 offset;
uniform mat4 projection;
uniform mat4 view;

void main() 
{
    norm = normal;
    vec3 p = pos + offset;
    gl_Position = projection * view * vec4(p.x, p.y, p.z, 1.0);
}