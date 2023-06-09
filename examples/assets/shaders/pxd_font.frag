#version 450
layout (location = 0) out vec4 color;

in vec4 vcolor;
in vec2 vtexcoord;

uniform sampler2D utexture;
const float width  = 0.5;
const float edge   = 0.15;
void main(){
 
  float distance = 1.0 - texture(utexture, vtexcoord).a;
  float alpha    = 1.0 - smoothstep(width, width + edge, distance);
  color = vec4(vcolor.rgb, alpha);
}