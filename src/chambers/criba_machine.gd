@tool
## La Criba (Sala 1): un tablero de piedra verde y bronce. A la izquierda, la tolva; por el
## canal de cristal avanzan las esferas numeradas hasta la compuerta, que las deja caer por la
## canaleta izquierda al Cáliz de la Paridad (PAR, dorado) o por la derecha al Crisol (IMPAR,
## rojo). Es el invocador del patrón Command: perform() ejecuta, una por una, las órdenes que
## dejó el programa (FilterCommand) con su animación.
class_name CribaMachine
extends CodeMachine

const CHANNEL_Y := -44.0
const GATE := Vector2(30, -44)
const SLOT_GAP := 15.0
const VISIBLE_SLOTS := 7
const CHALICE := Vector2(-4, -6)
const CRUCIBLE := Vector2(64, -6)
const SPLIT := Vector2(30, -26)

const OUTLINE := Color("14181c")
const STONE_DARK := Color("27342e")
const STONE := Color("3e5246")
const STONE_LIGHT := Color("6a8070")
const BRONZE := Color("b48a4e")
const BRONZE_DARK := Color("6e5232")
const GLASS := Color(0.62, 0.9, 1.0, 0.22)
const CYAN := Color("3fe0ff")
const GOLD := Color("ffc857")
const RED := Color("ff5a4e")

var rules: ParityFilter
var round_count := 3

var _kit: TileKit
var _bus: EventBus
var _data: Dictionary
var _text: Callable
var _rng := RandomNumberGenerator.new()
var _spheres: Array[Sphere] = []
var _on_gate: Sphere = null
var _gate_open := 0.0          # -1 a la izquierda (cáliz), 1 a la derecha (crisol)
var _round_lit: Array = [false, false, false]
var _round_shown := 0
var _speed := 1.0
var _filled := 0
var _font: Font = load(UIKit.PIXEL_FONT)

# Letreros y luces: nodos de la escena scenes/maquinas/criba.tscn
@onready var _hopper_label: Label = $Tolva
@onready var _gate_number: Label = $NumeroCompuerta
@onready var _chalice_light: PointLight2D = $LuzCaliz
@onready var _crucible_light: PointLight2D = $LuzCrisol


## Una esfera numerada: orbe pálido con el número grabado encima (se dibuja directo, con
## borde, para que se lea aunque la sala esté oscura).
class Sphere extends Node2D:
	var value := 0
	var tint := Color("e9f7ff")
	var font: Font

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 7.5, Color("14181c"))
		draw_circle(Vector2.ZERO, 6.5, tint)
		draw_circle(Vector2(-3, -3), 1.5, Color(1, 1, 1, 0.95))
		# El número se dibuja al doble y a media escala para que quede nítido
		var text := str(value)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
		draw_string_outline(font, Vector2(-w / 2.0, 7), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 4, Color(1, 1, 1, 0.9))
		draw_string(font, Vector2(-w / 2.0, 7), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("101418"))
		draw_set_transform(Vector2.ZERO)


func setup(kit: TileKit, bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	_kit = kit
	_bus = bus
	_data = data
	_text = text
	var seed_value := int(data.get("seed", 0))
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	round_count = (data.get("rounds", []) as Array).size()
	_round_lit.resize(round_count)
	_round_lit.fill(false)
	view_focus = Vector2(-6, -28)
	session.title = String(data.get("name", ""))
	session.file_name = String(data.get("file_name", "criba.py"))
	session.code = String(data.get("starter_code", ""))
	session.help = data.get("help", [])
	session.max_lines = int(data.get("max_lines", 0))
	session.machine = self
	# Los letreros del tablero salen de chambers.json
	$EtiquetaPar.text = String(data.get("chalice_label", "PAR"))
	$EtiquetaImpar.text = String(data.get("crucible_label", "IMPAR"))
	$Glifo.text = String(data.get("glyph", "n % 2"))
	connect_console(open_codex)
	new_rules()


func _draw() -> void:
	# Tablero de piedra con remates de bronce
	_box(Rect2(-104, -82, 196, 62), STONE_DARK)
	_box(Rect2(-100, -78, 188, 54), STONE)
	draw_rect(Rect2(-100, -78, 188, 3), STONE_LIGHT)
	draw_rect(Rect2(-104, -24, 196, 4), BRONZE_DARK)
	draw_rect(Rect2(-104, -84, 196, 3), BRONZE)
	# Lámparas de las rondas
	for i in round_count:
		var c := Vector2(58 + i * 9, -71)
		draw_circle(c, 3.5, OUTLINE)
		draw_circle(c, 2.5, GOLD if _round_lit[i] else Color("2a3036"))
	# Tolva (izquierda)
	var hopper := PackedVector2Array([Vector2(-102, -64), Vector2(-78, -64), Vector2(-84, -48), Vector2(-96, -48)])
	draw_colored_polygon(hopper, BRONZE)
	draw_polyline(hopper + PackedVector2Array([hopper[0]]), OUTLINE, 1.0)
	# Canal de cristal
	draw_rect(Rect2(-90, CHANNEL_Y - 8, GATE.x + 98, 16), OUTLINE)
	draw_rect(Rect2(-89, CHANNEL_Y - 7, GATE.x + 96, 14), Color("1a2b30"))
	draw_rect(Rect2(-89, CHANNEL_Y - 7, GATE.x + 96, 14), GLASS)
	draw_rect(Rect2(-89, CHANNEL_Y - 6, GATE.x + 96, 1), Color(1, 1, 1, 0.35))
	# Compuerta: una paleta de bronce que se inclina
	var tilt := _gate_open * 0.5
	var g1 := SPLIT + Vector2(-9, 0).rotated(tilt)
	var g2 := SPLIT + Vector2(9, 0).rotated(tilt)
	draw_line(GATE + Vector2(0, 8), SPLIT, OUTLINE, 3.0)
	draw_line(g1, g2, OUTLINE, 4.0)
	draw_line(g1, g2, BRONZE, 2.0)
	# Canaletas hacia el cáliz y el crisol
	for side in [-1.0, 1.0]:
		var target: Vector2 = CHALICE if side < 0 else CRUCIBLE
		var from: Vector2 = SPLIT + Vector2(side * 8, 3)
		var to: Vector2 = target + Vector2(-side * 4, -12)
		draw_line(from, to, OUTLINE, 5.0)
		draw_line(from, to, BRONZE_DARK, 3.0)
	# Cáliz de la Paridad
	var cup := CHALICE
	draw_rect(Rect2(cup.x - 2, cup.y - 2, 4, 8), OUTLINE)
	draw_rect(Rect2(cup.x - 6, cup.y + 4, 12, 3), OUTLINE)
	draw_rect(Rect2(cup.x - 5, cup.y + 4, 10, 2), BRONZE)
	var bowl := PackedVector2Array([Vector2(-10, -14), Vector2(10, -14), Vector2(6, -3), Vector2(-6, -3)])
	for i in bowl.size():
		bowl[i] += cup
	draw_colored_polygon(bowl, GOLD.darkened(0.15))
	draw_polyline(bowl + PackedVector2Array([bowl[0]]), OUTLINE, 1.0)
	var fill := clampf(_filled / 12.0, 0.0, 1.0)
	draw_rect(Rect2(cup.x - 8, cup.y - 13, 16, 2), GOLD.lightened(0.3 * fill))
	# Crisol: caldero de piedra con brasas
	var pot := CRUCIBLE
	draw_rect(Rect2(pot.x - 11, pot.y - 14, 22, 15), OUTLINE)
	draw_rect(Rect2(pot.x - 10, pot.y - 13, 20, 13), Color("3a3330"))
	draw_rect(Rect2(pot.x - 8, pot.y - 13, 16, 3), RED.lerp(Color("ffb347"), 0.5 + 0.5 * sin(_time * 7.0)))
	draw_rect(Rect2(pot.x - 12, pot.y - 15, 24, 2), BRONZE_DARK)


func _box(r: Rect2, color: Color) -> void:
	draw_rect(r.grow(1), OUTLINE)
	draw_rect(r, color)


# ------------------------------------------------------------------ esferas

## Esferas nuevas para todas las rondas (al empezar y después de cada fallo).
func new_rules() -> void:
	rules = ParityFilter.new(_data.get("rounds", []), _rng)
	_round_lit.fill(false)
	_filled = 0
	_show_round(0, rules.rounds[0])


## Pone en el canal (y la tolva) las esferas de la ronda. Antes de ejecutar solo se ve la
## ronda 1; las otras aparecen cuando la máquina las prueba.
func _show_round(index: int, values: Array) -> void:
	for s in _spheres:
		s.queue_free()
	_spheres.clear()
	if _on_gate:
		_on_gate.queue_free()
		_on_gate = null
	_round_shown = index
	for v in values:
		var s := Sphere.new()
		s.value = int(v)
		s.font = _font
		s.z_index = 2
		add_child(s)
		_spheres.append(s)
	_layout_spheres(false)


## La primera esfera queda junto a la compuerta; las que no caben esperan en la tolva.
func _slot(i: int) -> Vector2:
	if i < VISIBLE_SLOTS:
		return Vector2(GATE.x - 12 - i * SLOT_GAP, CHANNEL_Y)
	return Vector2(-90, -58)


func _layout_spheres(animate: bool) -> void:
	for i in _spheres.size():
		var s := _spheres[i]
		s.visible = i < VISIBLE_SLOTS
		if animate:
			create_tween().tween_property(s, "position", _slot(i), 0.18 / _speed)
		else:
			s.position = _slot(i)
	var waiting := maxi(0, _spheres.size() - VISIBLE_SLOTS)
	_hopper_label.text = "+%d" % waiting if waiting > 0 else ""


# ------------------------------------------------------------------ evaluar (sin dibujar)

func evaluate(source: String, sandbox: ScriptSandbox) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	for i in rules.rounds.size():
		rules.start_round(i)
		var result := sandbox.run(source, FilterAdapter.objects(rules, _text), session.max_steps)
		report.output += result.output
		if not result.ok:
			report.ok = false
			report.error = result.error_text()
			if i > 0:
				report.error = _text.call("criba_round_error", {"round": i + 1, "error": report.error})
			break
		rules.end_round()
		if rules.failed():
			break
	report.commands = rules.commands
	report.success = report.ok and not rules.failed()
	match rules.fault:
		ParityFilter.Fault.WRONG_SIDE:
			var key := "criba_wrong_even" if ParityFilter.is_even(rules.fault_value) else "criba_wrong_odd"
			report.message = _text.call(key, {"n": rules.fault_value, "round": rules.round_index + 1})
		ParityFilter.Fault.LEFT_OVER:
			report.message = _text.call("criba_left_over", {"n": rules.fault_value, "round": rules.round_index + 1})
		_:
			report.message = _text.call("criba_solved", {}) if report.success else ""
	return report


func status_text() -> String:
	return _text.call("criba_status", {"round": _round_shown + 1, "of": round_count})


# ------------------------------------------------------------------ mostrar (invocador)

func perform(report: CodeMachine.Report) -> void:
	for command: FilterCommand in report.commands:
		await command.run(self)
	_gate_number.text = ""
	if report.success:
		await _celebrate()
		mark_solved()
	else:
		await _wait(0.6)
		new_rules()


func load_round(index: int, values: Array) -> void:
	_speed = float((_data.get("playback_speed", [1.0, 1.8, 2.6]) as Array)[mini(index, 2)])
	if index != _round_shown or _spheres.size() != values.size():
		_show_round(index, values)
		await _wait(0.45)
	_round_shown = index
	_bus.publish(GameEvents.MACHINE_STEP)


func drop_to_gate() -> void:
	if _spheres.is_empty():
		return
	var sphere: Sphere = _spheres.pop_front()
	_on_gate = sphere
	sphere.visible = true
	_gate_number.text = str(sphere.value)
	_gate_number.add_theme_color_override("font_color", Color("ffe7a8"))
	var t := create_tween()
	t.tween_property(sphere, "position", GATE + Vector2(0, 0), 0.14 / _speed)
	t.tween_property(sphere, "position", SPLIT + Vector2(0, -7), 0.12 / _speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_layout_spheres(true)
	await t.finished
	_bus.publish(GameEvents.MACHINE_STEP)


func send_from_gate(to_chalice: bool, right: bool) -> void:
	var sphere := _on_gate
	_on_gate = null
	if sphere == null:
		return
	var side := -1.0 if to_chalice else 1.0
	var tilt := create_tween()
	tilt.tween_method(func(v: float): _gate_open = v, 0.0, side, 0.1 / _speed)
	await tilt.finished
	var target := (CHALICE if to_chalice else CRUCIBLE) + Vector2(0, -12)
	var roll := create_tween()
	roll.tween_property(sphere, "position", target, 0.3 / _speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await roll.finished
	create_tween().tween_method(func(v: float): _gate_open = v, side, 0.0, 0.12 / _speed)
	_gate_number.add_theme_color_override("font_color", (GOLD if to_chalice else RED) if right else RED)
	if not right:
		await _wrong(sphere, to_chalice)
		return
	_absorb(sphere, to_chalice)
	_bus.publish(GameEvents.MACHINE_GOOD)


func jam() -> void:
	_bus.publish(GameEvents.MACHINE_BAD)
	var smoke := _kit.particles(self, SPLIT, "Smoke", 14, 1.2)
	smoke.gravity = Vector2(0, -30)
	smoke.initial_velocity_max = 30.0
	smoke.emitting = true
	for i in 6:
		_gate_open = 0.25 * (1 if i % 2 == 0 else -1)
		await _wait(0.06)
	_gate_open = 0.0
	await _wait(0.8)
	smoke.queue_free()


func round_done(index: int) -> void:
	if index < _round_lit.size():
		_round_lit[index] = true
	_bus.publish(GameEvents.MACHINE_ROUND)
	await _wait(0.35)


# ------------------------------------------------------------------ efectos

func _absorb(sphere: Sphere, to_chalice: bool) -> void:
	var light := _chalice_light if to_chalice else _crucible_light
	sphere.tint = GOLD if to_chalice else RED
	sphere.queue_redraw()
	var t := create_tween()
	t.tween_property(light, "energy", 2.2, 0.06)
	t.tween_property(light, "energy", 0.8, 0.35)
	var s := create_tween()
	s.tween_property(sphere, "scale", Vector2.ONE * 0.1, 0.18 / _speed)
	s.tween_callback(sphere.queue_free)
	if to_chalice:
		_filled += 1
	else:
		var sparks := _kit.particles(self, CRUCIBLE + Vector2(0, -14), "Fire", 6, 0.5)
		sparks.gravity = Vector2(0, -40)
		sparks.emitting = true
		get_tree().create_timer(0.8).timeout.connect(sparks.queue_free)


## La esfera cayó del lado equivocado: salta en rojo con chispas y la máquina se traba.
func _wrong(sphere: Sphere, to_chalice: bool) -> void:
	_bus.publish(GameEvents.MACHINE_BAD)
	sphere.tint = RED
	sphere.queue_redraw()
	var sparks := _kit.particles(self, sphere.position, "Spark", 18, 0.7)
	sparks.emitting = true
	var smoke := _kit.particles(self, (CHALICE if to_chalice else CRUCIBLE) + Vector2(0, -10), "Smoke", 10, 1.2)
	smoke.gravity = Vector2(0, -30)
	smoke.emitting = true
	var t := create_tween()
	t.tween_property(sphere, "position:y", sphere.position.y - 18, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	await _wait(1.4)
	sphere.queue_free()
	sparks.queue_free()
	smoke.queue_free()


func _celebrate() -> void:
	var t := create_tween()
	t.tween_property(_chalice_light, "energy", 3.0, 0.5)
	t.parallel().tween_property(_chalice_light, "texture_scale", _chalice_light.texture_scale * 2.0, 0.5)
	await t.finished


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
