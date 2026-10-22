## Patrón State: reto de teclas del rúnico. Hay que pulsarlas en orden antes de que se acabe la barra.
class_name KeyChallengeState
extends GameState

const RESULT_TIME := 0.8

var keys: Array = []       # ["J", "D", "K", "S"]
var pool: Array = []
var ready_time := 1.0
var index := 0
var seconds := 3.0
var damage := 4    # mitades de corazón
var won := false
var finished := false

var _start_ms := 0
var _finish_ms := 0
var _wrong := ""


## Arma el reto sin repetir la misma tecla seguida.
static func random_keys(pool: Array, count: int) -> Array:
	var out: Array = []
	while out.size() < count:
		var k: String = pool[randi() % pool.size()]
		if out.is_empty() or out[-1] != k:
			out.append(k)
	return out


func enter(params: Dictionary = {}) -> void:
	keys = params.get("keys", ["J", "K"])
	seconds = float(params.get("seconds", 3.0))
	damage = int(params.get("damage", 4))
	pool = params.get("pool", ["A", "S", "D", "F", "J", "K", "L"])
	ready_time = float(params.get("ready", 1.0))
	index = 0
	won = false
	finished = false
	_wrong = ""
	_start_ms = Time.get_ticks_msec()
	game.player.controls_enabled = false
	Engine.time_scale = float(game.combat("challenge_time_scale", 0.15))


func exit() -> void:
	Engine.time_scale = 1.0


func touch_keys() -> Array:
	return [] if finished else pool


func handle_key(event: InputEventKey) -> bool:
	if finished or is_getting_ready():
		return true
	var pressed := OS.get_keycode_string(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode).to_upper()
	if not pressed in pool:
		return true
	if pressed == keys[index]:
		index += 1
		game.bus.publish(GameEvents.KEY_OK)
		if index >= keys.size():
			_finish(true)
	else:
		_wrong = pressed
		game.bus.publish(GameEvents.KEY_BAD)
		_finish(false)
	return true


## Al principio la barra no corre.
func is_getting_ready() -> bool:
	return (Time.get_ticks_msec() - _start_ms) / 1000.0 < ready_time


func time_left() -> float:
	return minf(seconds, seconds - ((Time.get_ticks_msec() - _start_ms) / 1000.0 - ready_time))


func update(_delta: float) -> void:
	if not finished:
		if time_left() <= 0.0:
			_finish(false)
		return
	if (Time.get_ticks_msec() - _finish_ms) / 1000.0 >= RESULT_TIME:
		game.machine.change("play")
		if not won:
			game.player.hurt(damage, game.player.global_position + Vector2(0, 1), true)


func _finish(success: bool) -> void:
	finished = true
	won = success
	_finish_ms = Time.get_ticks_msec()
	game.bus.publish(GameEvents.KEYS_WON if success else GameEvents.KEYS_LOST)


func draw(ui: UIKit) -> void:
	var s := ui.size()
	ui.dim(0.35)
	ui.vignette(0.55, Color(0.75, 0.05, 0.02))
	var hud := Hud.new()
	hud.draw_hearts(ui, game.health, 0.0)
	var box := 74.0
	var gap := 14.0
	var w := keys.size() * box + (keys.size() - 1) * gap
	var panel := Rect2((s.x - maxf(w, 560.0)) / 2.0 - 40, s.y * 0.30, maxf(w, 560.0) + 80, 270)
	ui.panel(panel)
	ui.text_centered(game.data.message("keys_title"), panel.position.y + 22, 34, UIKit.ALERT, "title")
	if is_getting_ready():
		ui.text_centered(game.data.message("keys_ready"), panel.position.y + 70, 22, UIKit.GOLD, "bold")
	else:
		ui.text_centered(game.data.message("keys_hint"), panel.position.y + 70, 19, UIKit.MUTED)
	var x := (s.x - w) / 2.0
	var y := panel.position.y + 112
	for i in keys.size():
		var r := Rect2(x + i * (box + gap), y, box, box)
		var fill := Color(0.08, 0.1, 0.14, 0.95)
		var border := Color("3a4556")
		var text_color := UIKit.TEXT
		if i < index:
			fill = Color(0.1, 0.35, 0.18, 0.95)
			border = UIKit.GOOD
			text_color = UIKit.GOOD
		elif i == index and not finished:
			border = UIKit.GOLD
			fill = Color(0.2, 0.15, 0.05, 0.95)
			r = r.grow(3.0 + 2.0 * sin(ui.time * 12.0))
		elif i == index and finished and not won:
			fill = Color(0.4, 0.06, 0.05, 0.95)
			border = UIKit.ALERT
		ui.rect(r, fill)
		ui.frame(r, border, 3.0)
		ui.text_centered(String(keys[i]), r.position.y + r.size.y / 2.0 - 22, 40, text_color, "title", r.get_center().x)
	# Barra de tiempo
	var frac := clampf(time_left() / seconds, 0.0, 1.0) if not finished else 0.0
	var bar := Rect2((s.x - w) / 2.0, y + box + 22, w, 12)
	ui.rect(bar, Color(1, 1, 1, 0.08))
	ui.rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), UIKit.GOLD if frac > 0.33 else UIKit.ALERT)
	if finished:
		var msg: String = game.data.message("keys_won") if won else game.data.message("keys_lost", {"n": damage / 2})
		ui.text_centered(msg, panel.end.y + 18, 26, UIKit.GOOD if won else UIKit.ALERT, "bold")
