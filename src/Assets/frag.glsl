#version 330 core

in vec3 norm;

out vec4 FragColor;

void main() 
{
    FragColor = vec4(0.8f + norm.x, 0.3f + norm.y, 0.2f + norm.z, 1.0f);
}