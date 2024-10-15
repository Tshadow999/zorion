#version 330 core
layout (location = 0) in vec3 pos;

uniform vec3 offset;
uniform mat4 projection;
// uniform mat4 view;
// uniform mat4 model;

void main() 
{
    vec3 p = pos + offset;
    gl_Position = vec4(p.x, p.y, p.z, 1.0); // projection *  ...
}