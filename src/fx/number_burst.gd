## Un guardián que cae se deshace en números: dígitos que saltan, caen y se apagan.
## Se crea en el lugar y se borra solo.
class_name NumberBurst
extends Node2D

const LIFE := 1.1

var count := 9
var tint := Color("9fb8a6")

var _t := 0.0
var _bits: Array = []      # [{text, pos, vel}]
var _font: Font = load(UIKit.PIXEL_FONT)


func _ready() -> void:
	z_index = 5
	for i in count:
		_bits.append({
			"text": str(randi() % 10),
			"pos": Vector2(randf_range(-5, 5), randf_range(-14, -2)),
			"vel": Vector2(randf_range(-38, 38), randf_range(-70, -30)),
			"cyan": i % 3 == 0,
		})


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	for bit in _bits:
		bit.vel.y += 160.0 * delta
		bit.pos += bit.vel * delta
	queue_redraw()


func _draw() -> void:
	var a := clampf((LIFE - _t) / 0.5, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	for bit in _bits:
		var c: Color = Color("3fe0ff") if bit.cyan else tint
		var p: Vector2 = bit.pos * 2.0
		draw_string_outline(_font, p, bit.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 5, Color(0.05, 0.07, 0.1, a))
		draw_string(_font, p, bit.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(c, a))
	draw_set_transform(Vector2.ZERO)
