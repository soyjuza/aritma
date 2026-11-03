## Controles táctiles (Android, o con --touch en el computador para probarlos).
## Cada botón simula su tecla de config.json, así el juego no se entera de que no hay teclado.
## El joystick mueve a Tala en el juego y en los menús hace de flechas.
class_name TouchControls
extends Control

const STICK_RADIUS := 100.0
const REPEAT_FIRST := 0.45     # menús: espera antes de repetir la flecha
const REPEAT_EVERY := 0.16
const RUN_AT := 0.9            # joystick casi al borde: corre
const MOVES := {"move_left": Vector2.LEFT, "move_right": Vector2.RIGHT, "move_up": Vector2.UP, "move_down": Vector2.DOWN}
const ARROWS := {Vector2.LEFT: KEY_LEFT, Vector2.RIGHT: KEY_RIGHT, Vector2.UP: KEY_UP, Vector2.DOWN: KEY_DOWN}

var game
var ui: UIKit

var _buttons: Array = []         # {label, key, at, r} de la pantalla actual
var _stick := ""                 # "", "move" (Tala) o "ui" (flechas de los menús)
var _touches: Dictionary = {}    # índice del dedo -> índice del botón, o -1 si es el joystick
var _stick_origin := Vector2.ZERO
var _stick_value := Vector2.ZERO
var _arrow := Vector2.ZERO       # flecha que se está repitiendo en los menús
var _repeat_wait := 0.0
var _mouse_eaten := false        # el ratón que Godot simula con el primer dedo
var _action_key := KEY_E         # lo que mandó ACCIÓN al apretarse (E usar o J golpear)

# Escribir un campo de texto (EN LÍNEA) con el teclado del sistema
var _entry := LineEdit.new()
var _entry_done := Button.new()
var _entry_shade := ColorRect.new()
var _entry_field: TextField


## ¿Se muestran los controles? En Android siempre; en el computador con --touch.
static func wanted() -> bool:
	return OS.has_feature("mobile") or "--touch" in OS.get_cmdline_user_args()


func _init(context) -> void:
	game = context
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui = UIKit.new(self)
	_entry_shade.color = Color(0.01, 0.02, 0.03, 0.85)
	_entry_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_entry_shade)
	_entry.anchor_left = 0.08
	_entry.anchor_right = 0.74
	_entry.anchor_top = 0.08
	_entry.anchor_bottom = 0.19
	_entry.add_theme_font_override("font", ui.font("body"))
	_entry.add_theme_font_size_override("font_size", 34)
	_entry.text_submitted.connect(func(_t): _close_entry(true))
	add_child(_entry)
	_entry_done.anchor_left = 0.76
	_entry_done.anchor_right = 0.92
	_entry_done.anchor_top = 0.08
	_entry_done.anchor_bottom = 0.19
	_entry_done.focus_mode = Control.FOCUS_NONE
	_entry_done.add_theme_font_override("font", ui.font("title"))
	_entry_done.add_theme_font_size_override("font_size", 28)
	_entry_done.pressed.connect(func(): _close_entry(true))
	add_child(_entry_done)
	_show_entry(false)


## Escribiendo en el teclado del sistema: el juego no recibe teclas.
func typing() -> bool:
	return _entry.visible


func _process(delta: float) -> void:
	_layout()
	_update_stick(delta)
	_fit_codex()
	queue_redraw()


# ------------------------------------------------------------------ botones de cada pantalla

func _layout() -> void:
	var s := size
	var state: String = game.machine.current_name
	_buttons = []
	_stick = "ui"
	var main_at := Vector2(s.x - 150, s.y - 140)
	var second_at := Vector2(s.x - 300, s.y - 95)
	var third_at := Vector2(s.x - 140, s.y - 300)
	var fourth_at := Vector2(s.x - 290, s.y - 240)
	match state:
		"play":
			_stick = "move"
			# Un solo botón usa lo que hay enfrente o, si no hay nada, golpea.
			# Correr no tiene botón: basta llevar el joystick hasta el borde.
			_add("touch_action", KEY_E, main_at, 68)
			_buttons[-1].or_hit = true
			_add("touch_jump", KEY_SPACE, second_at, 52)
			# Debajo de los corazones del HUD
			_add("touch_pause", KEY_ESCAPE, Vector2(s.x - 56, 172), 36)
			_add("touch_book", KEY_TAB, Vector2(s.x - 56, 256), 36)
			_add("touch_flag", KEY_Q, Vector2(s.x - 56, 340), 36)
		"codex":
			_stick = ""
			_add("touch_close", KEY_ESCAPE, Vector2(s.x - 50, 46), 34)
			_add("touch_run_code", KEY_F5, Vector2(s.x - 136, 46), 34)
		"keys":
			_stick = ""
			var pool: Array = game.machine.current.pool
			var gap := minf(118.0, (s.x - 80.0) / maxf(1.0, pool.size()))
			var x0 := s.x / 2.0 - gap * (pool.size() - 1) / 2.0
			for i in pool.size():
				var letter := String(pool[i])
				_buttons.append({"label": letter, "key": OS.find_keycode_from_string(letter), "at": Vector2(x0 + gap * i, s.y - 100), "r": minf(50.0, gap * 0.44)})
		"puzzle":
			_stick = ""
			_add("touch_rotate", KEY_R, main_at, 62)
			_add("touch_back", KEY_ESCAPE, second_at, 46)
		"quiz":
			_stick = ""    # las opciones se tocan directo
		"intro", "end", "credits":
			_stick = ""
			_add("touch_accept", KEY_ENTER, main_at, 64)
			if state != "end":
				_add("touch_back", KEY_ESCAPE, second_at, 46)
		"lobby", "watch":
			_add("touch_back", KEY_ESCAPE, second_at, 50)
		_:
			_add("touch_accept", KEY_ENTER, main_at, 64)
			_add("touch_back", KEY_ESCAPE, second_at, 50)
			if state == "admin":
				_add("touch_players", KEY_TAB, third_at, 46)
				_add("touch_kick", KEY_X, fourth_at, 40)
			elif state == "online" and game.machine.current.touch_field() != null:
				_add("touch_type", KEY_NONE, third_at, 52)


func _add(text_key: String, key: Key, at: Vector2, radius: float) -> void:
	_buttons.append({"label": game.data.message(text_key), "key": key, "at": at, "r": radius})


func _stick_home() -> Vector2:
	return Vector2(170, size.y - 170)


## Qué hay debajo del dedo: índice del botón, -1 el joystick, -2 nada.
func _hit(at: Vector2) -> int:
	for i in _buttons.size():
		if at.distance_to(_buttons[i].at) <= float(_buttons[i].r) * 1.2:
			return i
	if _stick != "" and at.x < size.x * 0.42 and at.y > size.y * 0.4:
		return -1
	return -2


# ------------------------------------------------------------------ entrada

func _input(event: InputEvent) -> void:
	if typing():
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_entry(false)
			get_viewport().set_input_as_handled()
		return
	# Godot también simula un ratón con el primer dedo: si cae en un botón no se usa
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		var local := make_input_local(event)
		if event is InputEventMouseButton and event.pressed:
			_mouse_eaten = _hit(local.position) != -2
		if _mouse_eaten:
			get_viewport().set_input_as_handled()
		if event is InputEventMouseButton and not event.pressed:
			_mouse_eaten = false
		return
	if event is InputEventScreenTouch:
		var touch := make_input_local(event) as InputEventScreenTouch
		if touch.pressed:
			var hit := _hit(touch.position)
			if hit == -2:
				return
			_touches[touch.index] = hit
			if hit == -1:
				_stick_origin = touch.position
				_stick_value = Vector2.ZERO
			else:
				_on_button(hit, true)
			get_viewport().set_input_as_handled()
		elif _touches.has(touch.index):
			var hit: int = _touches[touch.index]
			_touches.erase(touch.index)
			if hit == -1:
				_stick_value = Vector2.ZERO
			else:
				_on_button(hit, false)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _touches.get(event.index, -2) == -1:
		var drag := make_input_local(event) as InputEventScreenDrag
		_stick_value = ((drag.position - _stick_origin) / STICK_RADIUS).limit_length(1.0)
		get_viewport().set_input_as_handled()


func _on_button(index: int, down: bool) -> void:
	if index >= _buttons.size():
		return
	var key: Key = _buttons[index].key
	if _buttons[index].get("or_hit", false):
		if down:
			var play = game.machine.current
			_action_key = KEY_E if not play.has_method("can_interact") or play.can_interact() else KEY_J
		key = _action_key
	if key == KEY_NONE:
		if down:
			_open_entry(game.machine.current.touch_field())
		return
	_send_key(key, down)


## Simula una tecla (como si se apretara en el teclado).
func _send_key(key: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = down
	Input.parse_input_event(event)


func _tap(key: Key) -> void:
	_send_key(key, true)
	_send_key(key, false)


## El botón "atrás" de Android hace de Esc.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if typing():
			_close_entry(false)
		else:
			_tap(KEY_ESCAPE)


func _update_stick(delta: float) -> void:
	if not _touches.values().has(-1):
		_stick_value = Vector2.ZERO
	var value := _stick_value if _stick != "" else Vector2.ZERO
	# Juego: la fuerza del joystick va a las acciones de movimiento
	for action in MOVES:
		var strength := maxf(0.0, value.dot(MOVES[action])) if _stick == "move" else 0.0
		if strength > 0.0:
			Input.action_press(action, strength)
		elif Input.is_action_pressed(action) and not _key_held(action):
			Input.action_release(action)
	# Joystick hasta el borde: corre (así se salta un foso con un solo dedo en SALTO)
	if _stick == "move" and value.length() > RUN_AT:
		Input.action_press("run")
	elif Input.is_action_pressed("run") and not _key_held("run"):
		Input.action_release("run")
	# Menús: una flecha al inclinar y se repite si se mantiene
	var arrow := Vector2.ZERO
	if _stick == "ui" and value.length() > 0.55:
		arrow = Vector2(signf(value.x), 0) if absf(value.x) > absf(value.y) else Vector2(0, signf(value.y))
	if arrow != _arrow:
		_arrow = arrow
		_repeat_wait = REPEAT_FIRST
		if arrow != Vector2.ZERO:
			_tap(ARROWS[arrow])
	elif arrow != Vector2.ZERO:
		_repeat_wait -= delta
		if _repeat_wait <= 0.0:
			_repeat_wait = REPEAT_EVERY
			_tap(ARROWS[arrow])


## ¿Hay una tecla física apretada para la acción? (teclado conectado al celular)
func _key_held(action: String) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and Input.is_physical_key_pressed(event.physical_keycode):
			return true
	return false


## Con el teclado del sistema abierto, el editor del Códice sube.
func _fit_codex() -> void:
	var height := float(DisplayServer.virtual_keyboard_get_height())
	var screen := float(DisplayServer.window_get_size().y)
	game.codex.fit_keyboard(height / screen if game.codex.visible and screen > 0.0 else 0.0)


# ------------------------------------------------------------------ campo de texto

func _show_entry(on: bool) -> void:
	_entry.visible = on
	_entry_done.visible = on
	_entry_shade.visible = on


func _open_entry(field: TextField) -> void:
	if field == null:
		return
	_entry_field = field
	_entry.text = field.text
	_entry.max_length = field.max_length
	_entry_done.text = game.data.message("touch_done")
	_show_entry(true)
	_entry.grab_focus()
	_entry.caret_column = _entry.text.length()
	DisplayServer.virtual_keyboard_show(_entry.text, Rect2(), DisplayServer.KEYBOARD_TYPE_DEFAULT, field.max_length)


func _close_entry(keep: bool) -> void:
	if keep and _entry_field:
		_entry_field.set_text(_entry.text)
	_entry_field = null
	_entry.release_focus()
	_show_entry(false)
	DisplayServer.virtual_keyboard_hide()


# ------------------------------------------------------------------ dibujo

func _draw() -> void:
	if typing():
		return
	if _stick != "":
		var home := _stick_home() if not _touches.values().has(-1) else _stick_origin
		draw_circle(home, STICK_RADIUS, Color(0.03, 0.04, 0.06, 0.35))
		draw_arc(home, STICK_RADIUS, 0, TAU, 48, Color(UIKit.TEXT, 0.35), 3.0, true)
		draw_circle(home + _stick_value * STICK_RADIUS, 42, Color(UIKit.CYAN, 0.45 if _stick_value != Vector2.ZERO else 0.25))
	var pressed: Array = _touches.values()
	for i in _buttons.size():
		var b: Dictionary = _buttons[i]
		var down := i in pressed
		var r := float(b.r)
		draw_circle(b.at, r, Color(UIKit.GOLD, 0.45) if down else Color(0.03, 0.04, 0.06, 0.5))
		draw_arc(b.at, r, 0, TAU, 40, Color(UIKit.GOLD if down else UIKit.TEXT, 0.7), 3.0, true)
		var label := String(b.label)
		var font_size := 30 if label.length() <= 2 else (18 if r >= 50 else 15)
		var w := ui.measure(label, font_size, "bold")
		ui.text(label, b.at - Vector2(w / 2.0, ui.line_height(font_size, "bold") / 2.0), font_size, UIKit.TEXT, "bold")
