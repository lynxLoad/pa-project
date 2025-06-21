// outline.fp
varying vec2 v_texcoord0;
uniform sampler2D texture_sampler;
uniform vec4 tint;

// Параметры обводки (объявляем без значения по умолчанию)
uniform float outline_thickness; // Толщина обводки
uniform vec4 outline_color;     // Цвет обводки (RGBA)

void main()
{
	vec4 color = texture2D(texture_sampler, v_texcoord0);

	if (color.a < 0.5) {
		float max_alpha = 0.0;

		// Проверяем соседние пиксели
		for (float x = -outline_thickness; x <= outline_thickness; x += 1.0) {
			for (float y = -outline_thickness; y <= outline_thickness; y += 1.0) {
				if (x == 0.0 && y == 0.0) continue;

				vec2 offset = v_texcoord0 + vec2(x, y) / 512.0;
				max_alpha = max(max_alpha, texture2D(texture_sampler, offset).a);
			}
		}

		if (max_alpha > 0.5) {
			color = outline_color;
		}
	}

	gl_FragColor = color * tint;
}