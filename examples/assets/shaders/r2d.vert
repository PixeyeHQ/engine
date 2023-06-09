#version 450
layout (location = 0) in vec4  color;
layout (location = 1) in vec3  position;
layout (location = 2) in vec2  texcoord;

uniform mat4 umvp;

out vec4  vcolor;
out vec2  vtexcoord;

void main()
{
  vec4 finalPosition = umvp * vec4(position,1);
  gl_Position = finalPosition;
  vcolor    = color;
  vtexcoord = texcoord;
}
