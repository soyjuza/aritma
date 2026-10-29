## Esfera numerada de la Criba (dorada o gris).
class_name CribaSphere
extends Node2D

var value := 0
var gold := false
var tint := Color("e9f7ff")
var font: Font


func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.5, Color("14181c"))
	draw_circle(Vector2.ZERO, 6.5, tint if tint != Color("e9f7ff") or not gold else Color("ffd27a"))
	draw_circle(Vector2(-3, -3), 1.5, Color(1, 1, 1, 0.95))
	var text := str(value)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	draw_string_outline(font, Vector2(-w / 2.0, 7), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 4, Color(1, 1, 1, 0.9))
	draw_string(font, Vector2(-w / 2.0, 7), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("101418"))
	draw_set_transform(Vector2.ZERO)
