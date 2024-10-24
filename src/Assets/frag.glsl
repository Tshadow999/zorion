#version 330 core

in vec3 o_norm;
in vec2 o_uv;

out vec4 FragColor;

uniform vec4 u_tint;
uniform sampler2D u_texture;

void main() 
{
    vec3 lightDir = normalize(vec3(1.0f, 1.0f, 0.5f));

    float light = dot(o_norm, lightDir);
    vec3 diffuse = vec3(0.8f, 0.3f, 0.2f);
    vec4 tex = texture(u_texture, o_uv);
    vec3 color = diffuse * tex.rgb;

    FragColor = tex * u_tint;//  * light;
    // FragColor = u_tint * tex;
}