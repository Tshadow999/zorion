#version 330 core
layout (location = 0) in vec3 pos;
layout (location = 1) in vec2 uv;
layout (location = 2) in vec3 normal;
layout (location = 3) in vec4 color;

out vec3 norm;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

void main() 
{
    norm = normal;
    gl_Position = projection * view * model * vec4(pos, 1.0);
}