## Herramientas de dibujo con el estilo del juego: paneles de piedra oscura con borde dorado
## y detalles de circuito cian, títulos en Cinzel y texto en Exo 2.
## Todas las pantallas dibujan a través de esta clase, así el estilo vive en un solo lugar.
class_name UIKit
extends RefCounted

const TEXT := Color("ece4d0")
const MUTED := Color("8d97a8")
const GOLD := Color("e2b44f")
const GOLD_DARK := Color("7a5a22")
const CYAN := Color("4fe3ff")
const ALERT := Color("ff5a4e")
const GOOD := Color("6be38b")
const PANEL := Color(0.035, 0.045, 0.065, 0.88)
const PANEL_LIGHT := Color(0.09, 0.11, 0.15, 0.92)
const SHADE := Color(0.0, 0.0, 0.02, 0.6)

var time := 0.0
var _canvas: CanvasItem
const PIXEL_FONT := "res://assets/fonts/PixelifySans.ttf"

var _fonts: Dictionary = {}
var _vignette: GradientTexture2D


func _init(canvas: CanvasItem) -> void:
	_canvas = canvas
	# Fuente pixelada (Pixelify Sans) para que la interfaz combine con el pixel art
	_fonts["title"] = _variation(PIXEL_FONT, 700)
	_fonts["title_light"] = _variation(PIXEL_FONT, 500)
	_fonts["body"] = _variation(PIXEL_FONT, 400)
	_fonts["bold"] = _variation(PIXEL_FONT, 600)


static func _variation(path: String, weight: int) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = load(path)
	var ts := TextServerManager.get_primary_interface()
	font.variation_opentype = {ts.name_to_tag("wght"): weight}
	# Sin ligaduras: en Pixelify Sans la «fi» sale como una sola letra rara («Agura»)
	font.opentype_features = {ts.name_to_tag("liga"): 0}
	return font


func size() -> Vector2:
	return _canvas.get_viewport_rect().size


func font(name: String) -> Font:
	return _fonts.get(name, _fonts.body)


func rect(r: Rect2, color: Color) -> void:
	_canvas.draw_rect(r, color)


func frame(r: Rect2, color: Color, width := 2.0) -> void:
	_canvas.draw_rect(r, color, false, width)


func line(a: Vector2, b: Vector2, color: Color, width := 2.0) -> void:
	_canvas.draw_line(a, b, color, width, true)


func diamond(center: Vector2, half: float, color: Color) -> void:
	_canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -half), center + Vector2(half, 0), center + Vector2(0, half), center + Vector2(-half, 0)]), color)


func arc(center: Vector2, radius: float, from: float, to: float, color: Color, width := 2.0) -> void:
	_canvas.draw_arc(center, radius, from, to, 48, color, width, true)


## Panel principal: fondo oscuro, borde dorado y esquinas con detalle cian.
func panel(r: Rect2, fill := PANEL) -> void:
	rect(r, fill)
	frame(r, GOLD_DARK, 2.0)
	frame(r.grow(-5), Color(GOLD, 0.35), 1.0)
	var c := 14.0
	for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var dx := c if corner.x == r.position.x else -c
		var dy := c if corner.y == r.position.y else -c
		line(corner, corner + Vector2(dx, 0), CYAN, 3.0)
		line(corner, corner + Vector2(0, dy), CYAN, 3.0)


## Etiqueta redondeada pequeña (indicadores del HUD).
func pill(r: Rect2, fill := PANEL, border := GOLD_DARK) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(r.size.y / 2.0))
	style.anti_aliasing = true
	_canvas.draw_style_box(style, r)


## Texto con su esquina superior izquierda en "at".
func text(s: String, at: Vector2, font_size := 22, color := TEXT, font_name := "body", shadow := true) -> void:
	var f := font(font_name)
	var baseline := at + Vector2(0, f.get_ascent(font_size))
	if shadow:
		_canvas.draw_string(f, baseline + Vector2(2, 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.55))
	_canvas.draw_string(f, baseline, s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func text_centered(s: String, y: float, font_size := 22, color := TEXT, font_name := "body", center_x := -1.0) -> void:
	var cx := size().x / 2.0 if center_x < 0.0 else center_x
	text(s, Vector2(cx - measure(s, font_size, font_name) / 2.0, y), font_size, color, font_name)


func text_right(s: String, right_x: float, y: float, font_size := 22, color := TEXT, font_name := "body") -> void:
	text(s, Vector2(right_x - measure(s, font_size, font_name), y), font_size, color, font_name)


func measure(s: String, font_size := 22, font_name := "body") -> float:
	return font(font_name).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func line_height(font_size := 22, font_name := "body") -> float:
	return font(font_name).get_height(font_size) + 4.0


## Parte un texto en líneas que no superan "max_width" píxeles.
func wrap(s: String, max_width: float, font_size := 22, font_name := "body") -> Array:
	var out: Array = []
	var current := ""
	for word in s.split(" "):
		var candidate := word if current == "" else current + " " + word
		if current != "" and measure(candidate, font_size, font_name) > max_width:
			out.append(current)
			current = word
		else:
			current = candidate
	if current != "":
		out.append(current)
	return out


## Tecla dibujada como una pequeña placa: [Z] Hablar. Devuelve el ancho usado.
func key_hint(key: String, label_text: String, at: Vector2, font_size := 18) -> float:
	var kw := maxf(28.0, measure(key, font_size, "bold") + 14.0)
	pill(Rect2(at, Vector2(kw, font_size + 12)), PANEL_LIGHT, GOLD)
	text(key, at + Vector2((kw - measure(key, font_size, "bold")) / 2.0, 5), font_size, GOLD, "bold", false)
	text(label_text, at + Vector2(kw + 8, 5), font_size, TEXT)
	return kw + 8 + measure(label_text, font_size) + 22


func cursor(at: Vector2, color := GOLD) -> void:
	var s := 9.0 + sin(time * 6.0) * 1.5
	_canvas.draw_colored_polygon(PackedVector2Array([at, at + Vector2(0, s * 2), at + Vector2(s * 1.2, s)]), color)


func more_arrow(at: Vector2) -> void:
	var y := at.y + sin(time * 5.0) * 3.0
	_canvas.draw_colored_polygon(PackedVector2Array([Vector2(at.x, y), Vector2(at.x + 16, y), Vector2(at.x + 8, y + 10)]), CYAN)


func blink(rate := 2.0) -> bool:
	return int(time * rate) % 2 == 0


func dim(amount := 0.6) -> void:
	rect(Rect2(Vector2.ZERO, size()), Color(0.0, 0.01, 0.03, amount))


## Barra de nivel de 0 a "maximum" (volumen).
func bar(at: Vector2, level: int, maximum: int, color := GOOD) -> void:
	for k in maximum:
		var r := Rect2(at + Vector2(k * 22, 0), Vector2(16, 20))
		rect(r, color if k < level else Color(1, 1, 1, 0.08))
		frame(r, Color(0, 0, 0, 0.6), 1.0)


## Un trozo de una textura (un cuadro de una tira del pack) dibujado en "dest".
func texture_region(texture: Texture2D, dest: Rect2, source: Rect2, modulate := Color.WHITE) -> void:
	_canvas.draw_texture_rect_region(texture, dest, source, modulate)


## Viñeta en los bordes de la pantalla: oscura (ambiente de ruinas) o de color (la alarma).
func vignette(strength := 0.55, color := Color.BLACK) -> void:
	if _vignette == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 0))
		gradient.set_color(1, Color(1, 1, 1, 1))
		gradient.add_point(0.55, Color(1, 1, 1, 0))
		_vignette = GradientTexture2D.new()
		_vignette.gradient = gradient
		_vignette.fill = GradientTexture2D.FILL_RADIAL
		_vignette.fill_from = Vector2(0.5, 0.5)
		_vignette.fill_to = Vector2(1.05, 1.05)
		_vignette.width = 256
		_vignette.height = 256
	_canvas.draw_texture_rect(_vignette, Rect2(Vector2.ZERO, size()), false, Color(color, strength))
