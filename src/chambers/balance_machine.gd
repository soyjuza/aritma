@tool
## La Balanza de los Aritmanos (Sala 4): un pilar de piedra sobre un pozo de lava sostiene un
## brazo de bronce con dos platos colgados de cadenas. Arriba, en un estante, las pesas de
## piedra con su valor grabado y, debajo de cada una, su número de posición (0, 1, 2...), que es
## el que usa el código: plato_izq.poner(0). Se prueba con dos juegos de pesas: el que se ve y
## uno oculto. perform() lleva las pesas a los platos una por una y la balanza se inclina; si
## no queda nivelada, las pesas caen a la lava y llegan pesas nuevas.
class_name BalanceMachine
extends CodeMachine

const OUTLINE := Color("14181c")
const STONE := Color("5b4a42")
const STONE_LIGHT := Color("85705f")
const STONE_DARK := Color("3a2e29")
const BRONZE := Color("b48a4e")
const BRONZE_DARK := Color("6e5232")
const LAVA := Color("ff6a1f")
const LAVA_DARK := Color("b8320f")
const CYAN := Color("3fe0ff")
const GOLD := Color("ffc857")
const GREEN := Color("6be38b")
const RED := Color("ff5a4e")
const PIVOT := Vector2(0, -92)
const ARM := 74.0
const CHAIN := 30.0
const RACK_Y := -128.0
const STONE_W := 15.0
const STONE_H := 11.0

var round_sizes: Array = [7, 8]
var sets: Array = []              # un Array de pesas por ronda
var shown_round := 0

var _bus: EventBus
var _data: Dictionary
var _kit: TileKit
var _text: Callable
var _rng := RandomNumberGenerator.new()
var _font: Font = load(UIKit.PIXEL_FONT)
var _tilt := 0.0                  # inclinación del brazo (radianes, + = baja el derecho)
var _side: Array = []             # por pesa del juego mostrado: -1, LEFT o RIGHT
var _fly: Array = []              # por pesa: 0..1 (del estante al plato)
var _fall := 0.0                  # 0..1: las pesas caen a la lava
var _glow := 0.0                  # 0..1: brillo dorado al nivelar
var _hidden := false              # el juego oculto todavía no se ve

@onready var _light: PointLight2D = $Luz


func setup(kit: TileKit, bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	_kit = kit
	_bus = bus
	_data = data
	_text = text
	round_sizes = data.get("rounds", [7, 8])
	var seed_value := int(data.get("seed", 0))
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	view_focus = Vector2(0, -70)
	session.title = String(data.get("name", ""))
	session.file_name = String(data.get("file_name", "balanza.py"))
	session.code = String(data.get("starter_code", ""))
	session.help = data.get("help", [])
	session.machine = self
	connect_console(open_codex)
	new_sets()


## Pesas nuevas (al empezar y cada vez que caen a la lava).
func new_sets() -> void:
	sets.clear()
	for n in round_sizes:
		sets.append(BalanceRules.make_set(int(n), _rng, 2, 19, bool(_data.get("greedy", false))))
	_show_round(0, false)


func _show_round(index: int, hidden: bool) -> void:
	shown_round = index
	_hidden = hidden
	var count: int = sets[index].size()
	_side = []
	_side.resize(count)
	_side.fill(-1)
	_fly = []
	_fly.resize(count)
	_fly.fill(0.0)
	_fall = 0.0
	_tilt = 0.0


func status_text() -> String:
	return _text.call("balance_status", {"round": shown_round + 1, "of": sets.size()})


# ------------------------------------------------------------------ evaluar (sin dibujar)

func evaluate(source: String, sandbox: ScriptSandbox) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	report.success = true
	for r in sets.size():
		var rules := BalanceRules.new(sets[r])
		var result := sandbox.run(source, BalanceAdapter.objects(rules, _text), session.max_steps)
		report.output += result.output
		if not result.ok:
			report.ok = false
			report.error = result.error_text()
			if r > 0:
				report.error = _text.call("balance_round_error", {"round": r + 1, "error": report.error})
			report.success = false
			return report
		var verdict := rules.verdict()
		report.commands.append({"round": r, "order": rules.order, "verdict": verdict})
		if verdict != BalanceRules.Verdict.LEVEL:
			report.success = false
			match verdict:
				BalanceRules.Verdict.LEFT_OUT:
					report.message = _text.call("balance_left_out", {"round": r + 1, "list": str(rules.left_out())})
				_:
					report.message = _text.call("balance_unequal", {"round": r + 1, "left": rules.total(BalanceRules.LEFT), "right": rules.total(BalanceRules.RIGHT)})
			break
	if report.success:
		report.message = _text.call("balance_solved", {})
	return report


# ------------------------------------------------------------------ mostrar (invocador)

func perform(report: CodeMachine.Report) -> void:
	for step: Dictionary in report.commands:
		var r: int = step.round
		_show_round(r, false)
		_bus.publish(GameEvents.MACHINE_ROUND)
		await _wait(0.35)
		for put: Array in step.order:
			_side[put[0]] = put[1]
			_bus.publish(GameEvents.MACHINE_STEP)
			var t := create_tween()
			t.tween_method(func(k: float): _fly[put[0]] = k, 0.0, 1.0, 0.22)
			t.parallel().tween_property(self, "_tilt", _target_tilt(r), 0.22)
			await t.finished
		await _wait(0.3)
		if step.verdict == BalanceRules.Verdict.LEVEL:
			_bus.publish(GameEvents.MACHINE_GOOD)
			var g := create_tween()
			g.tween_property(self, "_glow", 1.0, 0.25)
			g.tween_property(self, "_glow", 0.0, 0.45)
			await g.finished
		else:
			await _drop_into_lava()
			new_sets()
			return
	if report.success:
		var t := create_tween()
		t.tween_property(_light, "energy", 1.8, 0.5)
		t.parallel().tween_property(_light, "color", GOLD, 0.5)
		await t.finished
		mark_solved()


## Cuánto se inclina el brazo con lo que hay en cada plato.
func _target_tilt(r: int) -> float:
	var left := 0
	var right := 0
	for i in _side.size():
		if _side[i] == BalanceRules.LEFT:
			left += int(sets[r][i])
		elif _side[i] == BalanceRules.RIGHT:
			right += int(sets[r][i])
	var total := maxi(1, left + right)
	return clampf(float(right - left) / total * 0.9, -0.32, 0.32)


func _drop_into_lava() -> void:
	_bus.publish(GameEvents.MACHINE_BAD)
	var tip := create_tween()
	tip.tween_property(self, "_tilt", 0.32 * signf(_tilt if _tilt != 0.0 else 1.0), 0.25)
	await tip.finished
	var fall := create_tween()
	fall.tween_property(self, "_fall", 1.0, 0.7)
	await fall.finished
	if _kit:
		var splash := _kit.particles(self, Vector2(0, -16), "Fire", 18, 0.8)
		splash.gravity = Vector2(0, 80)
		splash.initial_velocity_max = 60.0
		splash.finished.connect(splash.queue_free)
		splash.emitting = true
	await _wait(0.8)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


# ------------------------------------------------------------------ dibujo

func _plate_center(side: int) -> Vector2:
	var dir := Vector2.from_angle(_tilt)
	var end := PIVOT + dir * ARM * (1.0 if side == BalanceRules.RIGHT else -1.0)
	return end + Vector2(0, CHAIN)


func _rack_pos(i: int, count: int) -> Vector2:
	var gap := STONE_W + 4.0
	return Vector2(-(count - 1) * gap / 2.0 + i * gap, RACK_Y)


## Dónde queda la pesa i dentro de su plato (se apilan de a tres por fila).
func _plate_slot(i: int) -> Vector2:
	var side: int = _side[i]
	var k := 0
	for j in i:
		if _side[j] == side:
			k += 1
	var col := k % 3
	var row := k / 3
	return _plate_center(side) + Vector2((col - 1) * (STONE_W + 1.0), -5.0 - row * (STONE_H + 1.0))


func _draw() -> void:
	var time := Time.get_ticks_msec() / 1000.0
	# El pozo de lava
	var pool := Rect2(-108, -30, 216, 28)
	draw_rect(pool.grow(2), OUTLINE)
	draw_rect(pool, LAVA_DARK)
	for k in 6:
		var y := pool.position.y + 4 + k * 4
		var x := fmod(time * (10.0 + k * 3.0) + k * 37.0, pool.size.x)
		draw_rect(Rect2(pool.position.x + x - 20, y, 30, 2), Color(LAVA, 0.7))
		draw_rect(Rect2(pool.position.x + fmod(x + 110.0, pool.size.x) - 20, y + 1, 18, 1), Color(GOLD, 0.5))
	# El estante
	var rack := Rect2(-104, RACK_Y - 10, 208, 26)
	draw_rect(rack.grow(2), OUTLINE)
	draw_rect(rack, STONE_DARK)
	draw_rect(Rect2(rack.position.x, rack.end.y - 4, rack.size.x, 4), BRONZE_DARK)
	# El pilar
	draw_rect(Rect2(-7, PIVOT.y, 14, -PIVOT.y - 22).grow(1), OUTLINE)
	draw_rect(Rect2(-7, PIVOT.y, 14, -PIVOT.y - 22), STONE)
	draw_rect(Rect2(-7, PIVOT.y, 3, -PIVOT.y - 22), STONE_LIGHT)
	# El brazo y los platos
	var dir := Vector2.from_angle(_tilt)
	var a := PIVOT - dir * ARM
	var b := PIVOT + dir * ARM
	draw_line(a, b, OUTLINE, 5.0)
	draw_line(a, b, BRONZE.lerp(GOLD, _glow), 3.0)
	draw_circle(PIVOT, 5.0, OUTLINE)
	draw_circle(PIVOT, 4.0, BRONZE_DARK)
	for side in [BalanceRules.LEFT, BalanceRules.RIGHT]:
		var c := _plate_center(side)
		var top: Vector2 = a if side == BalanceRules.LEFT else b
		draw_line(top, c + Vector2(-20, 0), Color("8a8a8a"), 1.0)
		draw_line(top, c + Vector2(20, 0), Color("8a8a8a"), 1.0)
		var dish := PackedVector2Array([c + Vector2(-24, 0), c + Vector2(24, 0), c + Vector2(18, 5), c + Vector2(-18, 5)])
		draw_colored_polygon(dish, BRONZE.lerp(GOLD, _glow))
		draw_polyline(dish + PackedVector2Array([dish[0]]), OUTLINE, 1.0)
	# Las pesas
	if sets.is_empty():
		return
	var list: Array = sets[shown_round]
	for i in list.size():
		var from := _rack_pos(i, list.size())
		var at := from
		if _side[i] != -1:
			at = from.lerp(_plate_slot(i), _fly[i])
			if _fall > 0.0:
				at += Vector2(0, _fall * 70.0)
		var alpha := 1.0 - clampf(_fall * 1.4 - 0.4, 0.0, 1.0) if _side[i] != -1 else 1.0
		_draw_stone(at, "?" if _hidden else str(list[i]), alpha)
		_text_center(str(i), from + Vector2(0, 12), 7, Color(CYAN, 0.9))


func _draw_stone(center: Vector2, label: String, alpha: float) -> void:
	var r := Rect2(center - Vector2(STONE_W, STONE_H) / 2.0, Vector2(STONE_W, STONE_H))
	draw_rect(r.grow(1), Color(OUTLINE, alpha))
	draw_rect(r, Color(STONE_LIGHT, alpha))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(Color("a8927e"), alpha))
	_text_center(label, center + Vector2(0, 3.5), 8, Color(Color("1a1410"), alpha))


## Texto centrado, al doble de tamaño y a media escala (nítido con la cámara a 3x).
func _text_center(text: String, at: Vector2, size: int, color: Color) -> void:
	var big := size * 2
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
	draw_set_transform(at.round(), 0.0, Vector2(0.5, 0.5))
	draw_string(_font, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, big, color)
	draw_set_transform(Vector2.ZERO)
