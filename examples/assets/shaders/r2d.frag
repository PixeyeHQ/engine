#version 450
layout (location = 0) out vec4 color;

in vec4 vcolor;
in vec2 vtexcoord;

uniform sampler2D utexture;
const float cutoff = 0.005;
void main(){
 
  color  = texture(utexture, vtexcoord) * vcolor;
  if(color.a - cutoff < 0) discard;
}


