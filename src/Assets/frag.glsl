#version 330 core

in vec3 norm;

out vec4 FragColor;

void main() 
{
    vec3 lightDir = normalize(vec3(1.0f, 1.0f, -0.5f));

    float light = dot(norm, lightDir);
    vec3 diffuse = vec3(0.8f, 0.3f, 0.2f);
    vec3 color = diffuse * light;

    FragColor = vec4(color, 1.0f);
}