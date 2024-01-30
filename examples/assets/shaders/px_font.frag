#version 450
layout (location = 0) out vec4 color;

in vec4 vcolor;
in vec2 vtexcoord;

uniform sampler2D utexture;
uniform float outlineThickness = 0.0;
uniform vec4  outlineColor = vec4(0,0,0,1); // Color of the outline

uniform float width  = 0.25;
uniform float edge   = 0.1;

void main(){
  float distance     = 1.0 - texture(utexture, vtexcoord).a;
  float alpha        = 1.0 - smoothstep(width, width + edge, distance);
  float maxOutlineThickness = outlineThickness * (1.0-width);
  float outlineAlpha = 1.0 - smoothstep(width + maxOutlineThickness, width + edge + maxOutlineThickness, distance);
  if (distance > width && distance < width + maxOutlineThickness + edge){
      color = vec4(outlineColor.rgb, outlineAlpha * vcolor.a); // Use the outline color
  } else {
      color = vec4(vcolor.rgb, alpha * vcolor.a);
  }
}