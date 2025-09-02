#pragma header

#define texture flixel_texture2D
#define iResolution openfl_TextureSize
#define iChannel0 bitmap

uniform float r0 = 1.0;
uniform float r1 = 1.0;
uniform float r2 = 1.0;

uniform float g0 = 1.0;
uniform float g1 = 1.0;
uniform float g2 = 1.0;

uniform float b0 = 1.0;
uniform float b1 = 1.0;
uniform float b2 = 1.0;

uniform float mult = 1.0;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord.xy / iResolution.xy;

	vec4 col = texture(iChannel0, uv).xyzw;

	vec4 newCol = col;
	newCol.rgb = min(col.r * vec3(r0, r1, r2) + col.g * vec3(g0, g1, g2) + col.b * vec3(b0, b1, b2), vec3(1.0));
	newCol.a = col.a;
	
	vec4 colour = mix(col, newCol, mult);
	
	if(colour.a > 0.0)
		fragColor = vec4(colour.rgb, colour.a);
	else
		fragColor = vec4(0.0, 0.0, 0.0, 0.0);
}

void main()
{
	mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}