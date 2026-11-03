## La Tala de otro jugador, vista por el espectador. Se mueve con los estados que llegan.
## Se dibuja un poco en el pasado (DELAY) para tener siempre dos estados entre los que
## interpolar: así la red irregular no se ve a saltos.
class_name SpectatorGhost
extends Node2D

const SNAP_DISTANCE := 80.0    # más lejos que esto: salta en vez de deslizarse
const DELAY := 0.15            # segundos de colchón contra la latencia irregular
const MAX_SAMPLES := 40

var _samples: Array = []       # [{t, p, a, hop, w}], t en segundos del reloj del jugador
var world: WorldSync           # enemigos, jefe y orbes: van al mismo ritmo que Tala
var _offset := 0.0             # reloj local − reloj del jugador (con la latencia)
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


func set_lamp(dark: bool) -> void:
	_lamp.visible = dark


## s: un estado que mandó el jugador (ver Game.net_state).
func push(s: Dictionary) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var t := float(s.t) / 1000.0 if s.has("t") else now
	if not _samples.is_empty() and t <= float(_samples[-1].t):
		return
	var offset := now - t
	if _samples.is_empty() or offset < _offset:
		# El paquete más rápido marca la latencia
		_offset = offset
	else:
		# Si el reloj del jugador se corre, se ajusta despacio
		_offset = lerpf(_offset, offset, 0.02)
	var sample := {"t": t, "p": Vector2(float(s.get("x", 0)), float(s.get("y", 0))), "a": String(s.get("a", "idle_down")), "hop": float(s.get("hop", 0)), "w": s.get("w", {})}
	if _samples.is_empty():
		_show(sample.p, sample.a, sample.hop)
	_samples.append(sample)
	if _samples.size() > MAX_SAMPLES:
		_samples.pop_front()


func _process(_delta: float) -> void:
	if _samples.is_empty():
		return
	var at := Time.get_ticks_msec() / 1000.0 - _offset - DELAY
	while _samples.size() > 2 and float(_samples[1].t) <= at:
		_samples.pop_front()
	var a: Dictionary = _samples[0]
	if _samples.size() == 1 or at <= float(a.t):
		_show(a.p, a.a, a.hop)
		_world(a, a, 0.0)
		return
	var b: Dictionary = _samples[1]
	var w := clampf((at - float(a.t)) / maxf(float(b.t) - float(a.t), 0.001), 0.0, 1.0)
	_world(a, b, w)
	if (a.p as Vector2).distance_to(b.p) > SNAP_DISTANCE:
		# Cayó a un foso, murió o cambió de puerta: salta
		var near: Dictionary = a if w < 0.5 else b
		_show(near.p, near.a, near.hop)
		return
	_show((a.p as Vector2).lerp(b.p, w), String(b.a if w >= 0.5 else a.a), lerpf(a.hop, b.hop, w))


func _world(a: Dictionary, b: Dictionary, w: float) -> void:
	if world:
		world.apply(a.w, b.w, w)


func _show(at: Vector2, anim: String, hop: float) -> void:
	position = at
	if _sprite.sprite_frames.has_animation(anim) and _sprite.animation != anim:
		_sprite.play(anim)
	if anim.begins_with("idle"):
		_sprite.stop()
		_sprite.frame = 0
	elif not _sprite.is_playing():
		_sprite.play()
	_sprite.position = Vector2(0, -8 - hop)
