#pragma header

#define texture flixel_texture2D
#define iResolution openfl_TextureSize
#define iChannel0 bitmap

uniform float r = 25.0;   

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord.xy / iResolution.xy;

    float x, y, xx, yy, rr = r * r, dx, dy, w, w0;

    w0 = 0.3 / pow(r, 1.9);

    vec2 p;

    vec4 col = vec4(0.0, 0.0, 0.0, 0.0);

    for (dx = 1.0 / iResolution.x, x = -r, p.x = uv.x + (x * dx); x <= r; x++, p.x += dx)
	{ 
		xx = x * x;

		for (dy = 1.0 / iResolution.y, y = -r, p.y = uv.y + (y * dy); y <= r; y++, p.y += dy)
		{ 
			yy = y * y;

			if (xx + yy <= rr / 2)
			{
				w = w0 * exp((-xx - yy) / (rr));
				col += texture(iChannel0, p) * w;
			}
		}
	}

    fragColor = col;
}

void main() 
{
	mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}