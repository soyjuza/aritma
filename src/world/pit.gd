@tool
## Foso: si los pies de Tala quedan dentro sin saltar, cae.
class_name Pit
extends Node2D

signal fell

const MARGIN := 3.0

@export var size := Vector2(80, 48):
	set(value):
		size = value
		queue_redraw()

var active := true

var _falling := false


func rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or not active or _falling:
		return
	var player: PlayerController = get_tree().get_first_node_in_group("player")
	if player == null or player.airborne or player.falling:
		return
	if rect().grow(-MARGIN).has_point(to_local(player.global_position)):
		_falling = true
		await player.fall()
		_falling = false
		fell.emit()


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(rect(), Color(1.0, 0.3, 0.2, 0.25))
		draw_rect(rect(), Color(1.0, 0.3, 0.2, 0.9), false, 1.0)
