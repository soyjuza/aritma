## Muñeco de paja de la práctica: aguanta golpes y se tambalea.
class_name TrainingDummy
extends Node2D

signal hit

const WOOD := Color("6e4a2a")
const WOOD_DARK := Color("3d2716")
const STRAW := Color("d9b75e")
const STRAW_DARK := Color("9c7a32")
const RED := Color("c8483c")

var radius := 7.0
var hits := 0

var _wobble := 0.0
var _flash := 0.0


func _ready() -> void:
	add_to_group("boss")


func can_be_hit() -> bool:
	return visible


func take_hit(_amount: int, direction: Vector2) -> void:
	hits += 1
	_flash = 0.15
	_wobble = 0.35 * (signf(direction.x) if absf(direction.x) > 0.1 else 1.0)
	hit.emit()


func _process(delta: float) -> void:
	_wobble = move_toward(_wobble, 0.0, delta * 1.2)
	_flash = maxf(0.0, _flash - delta)
	rotation = sin(_wobble * 30.0) * _wobble
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, 1), 6.0, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-1.5, -16, 3, 17), WOOD_DARK)
	draw_rect(Rect2(-1, -16, 2, 16), WOOD)
	draw_rect(Rect2(-8, -13, 16, 3), WOOD_DARK)
	draw_rect(Rect2(-7.5, -12.5, 15, 2), WOOD)
	var body := STRAW.lerp(Color.WHITE, 0.6) if _flash > 0.0 else STRAW
	draw_rect(Rect2(-4.5, -12, 9, 9), STRAW_DARK)
	draw_rect(Rect2(-4, -11.5, 8, 8), body)
	draw_circle(Vector2(0, -7.5), 2.2, RED)
	draw_circle(Vector2(0, -7.5), 1.0, body)
	draw_circle(Vector2(0, -19), 4.0, STRAW_DARK)
	draw_circle(Vector2(0, -19), 3.4, body)
