shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

group_uniforms lens_distortion;
uniform bool ld_enabled = false;
uniform float barrel : hint_range(0.0, 0.5) = 0.08;

group_uniforms chromatic_aberration;
uniform bool ca_enabled = false;
uniform int levels : hint_range(2, 10) = 3;
uniform float spread : hint_range(0.00, 0.05, 0.001) = 0.01;
uniform float falloff : hint_range(0.0, 2.0) = 0.05;

group_uniforms film_grain;
uniform bool fg_enabled = false;
uniform float intensity : hint_range(0, 1.0, 0.001) = 0.5;

group_uniforms vignette;
uniform bool darken_enabled = false;
uniform float darken_amount : hint_range(0.0, 1.0) = 0.4;
uniform float darken_inner = 0.3;
uniform float darken_outer = 0.7;
uniform bool blur_enabled = false;
uniform float blur_amount : hint_range(0, 10) = 4.0;
uniform float blur_inner : hint_range(0, 1) = 0.5;
uniform float blur_outer : hint_range(0, 1) = 1.0;

// hash12 taken from Dave Hoskin's Hash without Sine
// https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec4 blurTexture(vec2 uv, float r) {
	if (blur_enabled) {
		float blur = smoothstep(blur_inner, blur_outer, r) * blur_amount;
		return textureLod(screen_texture, uv, blur);
	} else {
		return texture(screen_texture, uv);
	}
}

void fragment() {
    vec2 centered = SCREEN_UV - vec2(0.5);
	vec2 uv = SCREEN_UV;
	vec3 col = vec3(0);
	float r = length(centered);

	if (ld_enabled) {
	    float r2 = dot(centered, centered);
		centered *= (1. + barrel * r2) / (1. + 0.5 * barrel);
	    uv = centered + vec2(0.5);
	}

	// taken from Hayden
	// https://godotshaders.com/shader/chromatic-abberation/
	if (ca_enabled) {
		vec3 sum = vec3(0);
		vec2 offset = centered*spread*pow(r, falloff);
		float tf = 2.0/float(levels-1);
		for(int i = 0; i < levels; i++){
			float t = float(i)*tf; // range 0.0->2.0
			vec3 slice = vec3(1.0-t, 1.0 - abs(t - 1.0), t - 1.0);
			slice = max(slice, 0.0);
			sum += slice;
			vec2 slice_offset = (t - 1.0) * offset;
			col += slice * blurTexture(uv + slice_offset, r).rgb;
		}
		col /= sum;
	} else {
		col = blurTexture(uv, r).rgb;
	}
	
	if (fg_enabled) {
		float noise = hash12(uv*1500.+TIME);
		col += noise * intensity;
	}
	
	if (darken_enabled) {
		float darken = smoothstep(darken_inner, darken_outer, r) * darken_amount;
		col = mix(col, vec3(0.), darken);
	}

    COLOR = vec4(col, 1.0);
}