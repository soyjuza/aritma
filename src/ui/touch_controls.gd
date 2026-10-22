## Controles del celular: palanca a la izquierda y botones a la derecha.
## Cada estado dice qué necesita (touch_buttons, touch_stick, touch_tap, touch_keys).
## Un botón puede traer otra etiqueta: "cancel:skip" usa el texto "skip" de touch_names.
## Los botones mandan las mismas acciones que el teclado: el resto del juego no cambia.
class_name TouchControls
extends Control

const STICK_RADIUS := 120.0
const DEAD := 0.2
const KEY_SIZE := 112.0
const KEY_GAP := 14.0
## Dónde va cada botón: ancla en la pantalla, corrimiento y radio.
const LAYOUT := {
	"attack": [Vector2(1, 1), Vector2(-150, -150), 108.0],
	"jump": [Vector2(1, 1), Vector2(-385, -100), 84.0],
	"interact": [Vector2(1, 1), Vector2(-140, -395), 84.0],
	"run": [Vector2(1, 1), Vector2(-385, -300), 70.0],
	"flag": [Vector2(1, 1), Vector2(-600, -100), 78.0],
	"pause": [Vector2(0, 0), Vector2(72, 205), 50.0],
	"book": [Vector2(0, 0), Vector2(190, 205), 50.0],
	"cancel": [Vector2(1, 1), Vector2(-85, -85), 62.0],
	"ui_left": [Vector2(0, 0.5), Vector2(85, 0), 62.0],
	"ui_right": [Vector2(1, 0.5), Vector2(-85, 0), 62.0],
}
## Botones que se prenden y apagan con un toque.
const TOGGLES := ["run"]

var game
var names: Dictionary = {}    # acción → texto del botón

var _ui: UIKit
var _state: GameState
var _stick_finger := -1
var _stick_base := Vector2.ZERO
var _stick := Vector2.ZERO
var _fingers := {}    # dedo → acción apretada
var _sent := {}       # acción → fuerza enviada
var _taps: Array = []    # acciones que se sueltan en el siguiente cuadro
var _mouse_finger := false    # --tactil en el PC: el ratón hace de dedo
var _running := false    # CORRER prendido


func setup(p_game, p_names: Dictionary, mouse_as_finger: bool) -> void:
	game = p_game
	names = p_names
	_mouse_finger = mouse_as_finger
	_ui = UIKit.new(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = true


func _process(delta: float) -> void:
	if game == null:
		return
	_ui.time += delta
	for action in _taps:
		_send(action, 0.0)
	_taps.clear()
	# Al cambiar de estado se sueltan los botones
	if game.machine.current != _state:
		_state = game.machine.current
		_release_all()
	queue_redraw()


# ------------------------------------------------------------------ qué se muestra

func _buttons() -> Array:
	return _state.touch_buttons() if _state else []


static func _action_of(entry: String) -> String:
	return entry.get_slice(":", 0)


func _button_center(action: String) -> Vector2:
	var spot: Array = LAYOUT.get(action, [Vector2.ZERO, Vector2.ZERO, 0.0])
	return spot[0] * size + spot[1]


func _button_radius(action: String) -> float:
	return float(LAYOUT.get(action, [0, 0, 0.0])[2])


func _button_at(point: Vector2) -> String:
	for entry in _buttons():
		var action := _action_of(entry)
		# Un poco más grande que el dibujo para no fallar con el dedo
		if point.distance_to(_button_center(action)) <= _button_radius(action) * 1.15:
			return action
	return ""


func _key_rect(i: int, count: int) -> Rect2:
	var w := count * KEY_SIZE + (count - 1) * KEY_GAP
	return Rect2((size.x - w) / 2.0 + i * (KEY_SIZE + KEY_GAP), size.y - KEY_SIZE - 28, KEY_SIZE, KEY_SIZE)


func _key_at(point: Vector2) -> String:
	var keys: Array = _state.touch_keys() if _state else []
	for i in keys.size():
		if _key_rect(i, keys.size()).grow(6).has_point(point):
			return String(keys[i])
	return ""


func _stick_zone(point: Vector2) -> bool:
	return _state != null and _state.touch_stick() and point.x < size.x * 0.45 and point.y > size.y * 0.3


func _stick_rest() -> Vector2:
	return Vector2(230, size.y - 215)


# ------------------------------------------------------------------ entrada

func _input(event: InputEvent) -> void:
	if game == null or _state == null:
		return
	if _mouse_finger and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_finger_down(0, _local(event)) if event.pressed else _finger_up(0)
		_swallow_mouse(event)
	elif _mouse_finger and event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_finger_move(0, _local(event))
		_swallow_mouse(event)
	elif event is InputEventScreenTouch:
		var used := _finger_down(event.index, _local(event)) if event.pressed else _finger_up(event.index)
		if used:
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if _finger_move(event.index, _local(event)):
			get_viewport().set_input_as_handled()
	elif event is InputEventMouse:
		_swallow_mouse(event)


func _local(event: InputEvent) -> Vector2:
	return make_input_local(event).position


## El clic que sale del dedo no debe llegar al juego si cayó en un botón.
func _swallow_mouse(event: InputEventMouse) -> void:
	var point := _local(event)
	if _button_at(point) != "" or _key_at(point) != "" or _stick_finger >= 0 or _stick_zone(point):
		get_viewport().set_input_as_handled()


## true si el dedo cayó en un control táctil.
func _finger_down(finger: int, point: Vector2) -> bool:
	var key := _key_at(point)
	if key != "":
		_press_key(key)
		return true
	var action := _button_at(point)
	if action in TOGGLES:
		_running = not _running
		_fingers[finger] = ""
		_move(_stick)
		return true
	if action != "":
		_fingers[finger] = action
		_send(action, 1.0)
		return true
	if _stick_finger < 0 and _stick_zone(point):
		_stick_finger = finger
		_stick_base = point
		_stick = Vector2.ZERO
		return true
	var tap: String = _state.touch_tap()
	if tap != "":
		_send(tap, 1.0)
		_taps.append(tap)
		return true
	return false


func _finger_up(finger: int) -> bool:
	if _fingers.has(finger):
		if _fingers[finger] != "":
			_send(_fingers[finger], 0.0)
		_fingers.erase(finger)
		return true
	if finger == _stick_finger:
		_stick_finger = -1
		_move(Vector2.ZERO)
		return true
	return false


func _finger_move(finger: int, point: Vector2) -> bool:
	if finger != _stick_finger:
		return false
	var offset := (point - _stick_base).limit_length(STICK_RADIUS * 1.6)
	# Si el dedo se pasa del borde, la palanca lo sigue
	if offset.length() > STICK_RADIUS:
		_stick_base = point - offset.normalized() * STICK_RADIUS
	_move((point - _stick_base) / STICK_RADIUS)
	return true


## Palanca → acciones de movimiento con fuerza.
func _move(v: Vector2) -> void:
	_stick = v.limit_length(1.0)
	var live := _stick if _stick.length() > DEAD else Vector2.ZERO
	_send("move_right", maxf(live.x, 0.0))
	_send("move_left", maxf(-live.x, 0.0))
	_send("move_down", maxf(live.y, 0.0))
	_send("move_up", maxf(-live.y, 0.0))
	_send("run", 1.0 if _running and live != Vector2.ZERO else 0.0)


func _send(action: String, strength: float) -> void:
	if is_equal_approx(float(_sent.get(action, 0.0)), strength):
		return
	_sent[action] = strength
	var event := InputEventAction.new()
	event.action = action
	event.pressed = strength > 0.0
	event.strength = strength
	Input.parse_input_event(event)


## Una tecla en pantalla (reto del rúnico).
func _press_key(letter: String) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = OS.find_keycode_from_string(letter)
		event.physical_keycode = event.keycode
		event.pressed = pressed
		Input.parse_input_event(event)


func _release_all() -> void:
	for action in _sent.keys():
		_send(action, 0.0)
	_fingers.clear()
	_stick_finger = -1
	_stick = Vector2.ZERO


# ------------------------------------------------------------------ dibujo

func _draw() -> void:
	if game == null or _state == null:
		return
	if _state.touch_stick():
		_draw_stick()
	for entry in _buttons():
		_draw_button(entry)
	var keys: Array = _state.touch_keys()
	for i in keys.size():
		var r := _key_rect(i, keys.size())
		_ui.rect(r, Color(0.06, 0.08, 0.11, 0.9))
		_ui.frame(r, UIKit.GOLD, 3.0)
		_ui.text_centered(String(keys[i]), r.position.y + r.size.y / 2.0 - 28, 48, UIKit.GOLD, "title", r.get_center().x)


func _draw_stick() -> void:
	var active := _stick_finger >= 0
	var base := _stick_base if active else _stick_rest()
	draw_circle(base, STICK_RADIUS, Color(0.04, 0.055, 0.08, 0.35 if active else 0.2))
	_ui.arc(base, STICK_RADIUS, 0, TAU, Color(UIKit.CYAN, 0.55 if active else 0.25), 3.0)
	var knob := base + _stick * STICK_RADIUS
	draw_circle(knob, 52, Color(UIKit.GOLD if _running else UIKit.CYAN, 0.55 if active else 0.25))


func _draw_button(entry: String) -> void:
	var action := _action_of(entry)
	var center := _button_center(action)
	var radius := _button_radius(action)
	var held := action in _fingers.values() or (action in TOGGLES and _running)
	var ready := action == "interact" and _has_prompt()
	var ring := UIKit.GOLD
	if ready:
		ring = Color(UIKit.GOLD, 0.7 + 0.3 * sin(_ui.time * 6.0))
	draw_circle(center, radius, Color(UIKit.GOLD, 0.4) if held else Color(0.04, 0.055, 0.08, 0.5 if ready else 0.32))
	_ui.arc(center, radius, 0, TAU, ring if ready or held else Color(UIKit.GOLD, 0.5), 4.0 if ready else 2.5)
	var label := String(names.get(entry.get_slice(":", 1) if ":" in entry else action, action))
	if ready:
		_draw_prompt(center + Vector2(0, -radius - 22))
	var font_size := int(clampf(radius * 0.34, 18, 32))
	_ui.text_centered(label, center.y - font_size * 0.62, font_size, UIKit.TEXT, "bold", center.x)


## Hay algo para usar delante de Tala.
func _has_prompt() -> bool:
	return _prompt_text() != ""


func _prompt_text() -> String:
	var seen: Interactable = game.player.focused_interactable()
	if seen:
		return game.data.message(seen.prompt_key)
	return String(game.level.action_prompt().get("text", ""))


## Lo que hace USAR, encima del botón.
func _draw_prompt(bottom: Vector2) -> void:
	var text := _prompt_text()
	var w := _ui.measure(text, 20) + 28
	var r := Rect2(minf(bottom.x - w / 2.0, size.x - w - 16), bottom.y - 38, w, 38)
	_ui.rect(r, Color(0.04, 0.055, 0.08, 0.85))
	_ui.frame(r, UIKit.GOLD, 1.5)
	_ui.text(text, r.position + Vector2(14, 8), 20)
