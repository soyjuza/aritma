## Cámara: sigue a Tala, tiembla con los golpes y encuadra las máquinas.
## El zoom es entero para que el pixel art se vea nítido.
class_name CameraRig
extends Camera2D

var target: Node2D
var base_zoom := 3.0
var frame_zoom := 3.0    # para encuadrar máquinas (en el celular base_zoom es mayor)
var fixed_shot := false

var _bounds := Rect2i()    # límites del nivel en píxeles
var _shake := 0.0
var _frame_from := Vector2.ZERO
var _frame_to := Vector2.ZERO
var _zoom_from := 1.0
var _zoom_to := 1.0
var _t := 1.0
var _glide_time := 0.6


func _ready() -> void:
	position_smoothing_enabled = false
	get_viewport().size_changed.connect(_snap_zoom)
	_snap_zoom()


## Zoom entero según el tamaño real de la ventana.
func _snap_zoom(extra := 1.0) -> void:
	var stretch := get_viewport().get_final_transform().get_scale().x
	var want := base_zoom * extra * stretch
	var whole := maxf(1.0, roundf(want))
	zoom = Vector2.ONE * (whole / stretch)


## Bordes del nivel que la cámara no pasa.
func set_bounds(pixels: Rect2i) -> void:
	_bounds = pixels
	_apply_limits(not fixed_shot)


func _apply_limits(on: bool) -> void:
	var free := not on or _bounds.size == Vector2i.ZERO
	limit_left = -10000000 if free else _bounds.position.x
	limit_top = -10000000 if free else _bounds.position.y
	limit_right = 10000000 if free else _bounds.end.x
	limit_bottom = 10000000 if free else _bounds.end.y


func follow(node: Node2D) -> void:
	target = node
	fixed_shot = false
	_apply_limits(true)
	_t = 1.0
	_snap_zoom()
	if node:
		global_position = node.global_position + Vector2(0, -8)


## Plano fijo mirando un punto (título, máquinas).
func frame(at: Vector2, zoom_factor := 1.0, seconds := 0.6) -> void:
	fixed_shot = true
	# Junto a una máquina puede pasar los límites del nivel
	_frame_from = get_screen_center_position()
	_apply_limits(false)
	_frame_to = at
	_zoom_from = zoom.x
	var stretch := get_viewport().get_final_transform().get_scale().x
	_zoom_to = maxf(1.0, roundf(frame_zoom * zoom_factor * stretch)) / stretch
	_glide_time = maxf(seconds, 0.01)
	_t = 0.0


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func is_gliding() -> bool:
	return _t < 1.0


func _process(delta: float) -> void:
	if fixed_shot:
		if _t < 1.0:
			_t = minf(1.0, _t + delta / _glide_time)
			var k := smoothstep(0.0, 1.0, _t)
			global_position = _frame_from.lerp(_frame_to, k)
			zoom = Vector2.ONE * lerpf(_zoom_from, _zoom_to, k)
	elif target:
		var goal := target.global_position + Vector2(0, -8)
		global_position = global_position.lerp(goal, minf(1.0, delta * 9.0))
	if _shake > 0.0:
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
		_shake = maxf(0.0, _shake - delta * 12.0)
	else:
		offset = Vector2.ZERO
