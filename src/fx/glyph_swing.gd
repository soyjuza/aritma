## Rastro del golpe de garrote: un arco y símbolos que salen volando.
class_name GlyphSwing
extends Node2D

const GLYPHS := ["+", "−", "×", "÷", "=", "<", ">", "{", "}", ";", "%", "!=", "==", "()", "[]", "+="]
const LIFE := 0.5
const RADIUS := 15.0
const ARC := 1.2

var direction := Vector2.DOWN

var _t := 0.0
var _bits: Array = []
var _font: Font = load(UIKit.PIXEL_FONT)


func _ready() -> void:
	z_index = 5
	var base := direction.angle()
	for i in 3:
		_bits.append({
			"text": GLYPHS[randi() % GLYPHS.size()],
			"angle": base + randf_range(-ARC, ARC),
			"speed": randf_range(28.0, 46.0),
			"color": Color("3fe0ff") if i % 2 == 0 else Color("ffc857"),
		})


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	var base := direction.angle()
	# El arco se apaga desde la cola
	var alpha := 1.0 - k
	var from := base - ARC + ARC * 2.0 * minf(1.0, k * 2.5) * 0.35
	draw_arc(Vector2.ZERO, RADIUS, from, base + ARC, 14, Color(0.25, 0.88, 1.0, 0.75 * alpha), 2.0)
	draw_arc(Vector2.ZERO, RADIUS - 2.0, from, base + ARC, 14, Color(1, 1, 1, 0.45 * alpha), 1.0)
	# Al doble y a media escala para que se vean nítidos
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	for bit in _bits:
		var at: Vector2 = Vector2.from_angle(bit.angle) * (RADIUS * 0.6 + bit.speed * _t) * 2.0
		var c: Color = bit.color
		var a := clampf(1.2 - k * 1.2, 0.0, 1.0)
		var w := _font.get_string_size(bit.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		var p := at + Vector2(-w / 2.0, 8)
		draw_string_outline(_font, p, bit.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 5, Color(0.05, 0.07, 0.1, a))
		draw_string(_font, p, bit.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(c, a))
	draw_set_transform(Vector2.ZERO)
