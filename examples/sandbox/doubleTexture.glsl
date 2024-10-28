#version 330 core

in vec3 o_norm;
in vec2 o_uv;

out vec4 FragColor;

uniform sampler2D u_texture1;
uniform sampler2D u_texture2;
uniform vec4 u_tint;

void main() 
{
    vec4 tex1 = texture(u_texture1, o_uv);
    vec4 tex2 = texture(u_texture2, o_uv);
    FragColor = mix(tex1, tex2, 0.5f) * u_tint;
}