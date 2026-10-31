## La Tala de otro jugador, vista por el espectador. Se mueve con los estados que llegan.
class_name SpectatorGhost
extends Node2D

const SNAP_DISTANCE := 80.0    # más lejos que esto: salta en vez de deslizarse

var _target := Vector2.ZERO
var _placed := false
var _sprite: AnimatedSprite2D
var _lamp: PointLight2D


## Copia la sombra, el dibujo y la lámpara de Tala.
func build(player: PlayerController) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player.get_node("Sombra").duplicate())
	_sprite = player.get_node("Sprite").duplicate()
	add_child(_sprite)
	_lamp = player.get_node("Lampara").duplicate()
	add_child(_lamp)


## s: el estado que manda el jugador (ver Game.net_state).
func apply(s: Dictionary, dark: bool) -> void:
	var at := Vector2(float(s.get("x", 0)), float(s.get("y", 0)))
	if not _placed or at.distance_to(position) > SNAP_DISTANCE:
		position = at
		_placed = true
	_target = at
	var anim := String(s.get("a", "idle_down"))
	if _sprite.sprite_frames.has_animation(anim) and _sprite.animation != anim:
		_sprite.play(anim)
	if anim.begins_with("idle"):
		_sprite.stop()
		_sprite.frame = 0
	elif not _sprite.is_playing():
		_sprite.play()
	_sprite.position = Vector2(0, -8 - float(s.get("hop", 0)))
	_lamp.visible = dark


func _process(delta: float) -> void:
	position = position.lerp(_target, minf(1.0, delta * 14.0))
