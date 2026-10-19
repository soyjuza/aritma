@tool
## Pedestal de piedra de una estatua de guardián (escena: scenes/objetos/estatua_guardian.tscn).
## La estatua es su hijo «Caballero» (el caballero dorado, dormido). Cuando despierta, el pedestal queda vacío y con escombros.
class_name Pedestal
extends Node2D

const OUTLINE := Color("14181c")
const STONE := Color("59625f")
const STONE_LIGHT := Color("8a948f")
const STONE_DARK := Color("3a413f")

@export var rubble := false:
	set(value):
		rubble = value
		queue_redraw()


func _draw() -> void:
	var top := Rect2(-12, -10, 24, 4)
	var front := Rect2(-12, -6, 24, 8)
	draw_rect(Rect2(-13, -11, 26, 14), OUTLINE)
	draw_rect(front, STONE)
	draw_rect(top, STONE_LIGHT)
	draw_rect(Rect2(-12, 0, 24, 2), STONE_DARK)
	# Una franja grabada en el frente
	draw_rect(Rect2(-8, -3, 16, 1), STONE_DARK)
	if rubble:
		for chunk in [Rect2(-9, -12, 5, 3), Rect2(-2, -13, 4, 3), Rect2(4, -12, 6, 3), Rect2(-5, -11, 2, 2)]:
			draw_rect(chunk.grow(1), OUTLINE)
			draw_rect(chunk, STONE_LIGHT)
