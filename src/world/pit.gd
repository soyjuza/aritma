@tool
## Foso: un rectángulo de vacío (el dibujo son los tiles del Suelo; este nodo es la trampa).
## Si los pies del jugador quedan dentro sin estar en el aire, cae. Se mira el punto de los
## pies (no el cuerpo entero) para que sea justo: pisar el borde no tumba. En el editor se ve
## como un recuadro rojo; su tamaño se cambia en el Inspector.
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
