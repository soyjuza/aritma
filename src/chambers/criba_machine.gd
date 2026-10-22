@tool
## La Criba (Sala 1). Patrón Command: perform() ejecuta las órdenes (FilterCommand).
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
var _spheres: Array[CribaSphere] = []
var _on_gate: CribaSphere = null
var _gate_open := 0.0    # -1 cáliz, 1 crisol
var _round_lit: Array = [false, false, false]
var _round_shown := 0
var _speed := 1.0
var _filled := 0
var _font: Font = load(UIKit.PIXEL_FONT)

@onready var _hopper_label: Label = $Tolva
@onready var _gate_number: Label = $NumeroCompuerta
@onready var _chalice_light: PointLight2D = $LuzCaliz
@onready var _crucible_light: PointLight2D = $LuzCrisol


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
	session.set_blocks(data.get("blocks", []))
	session.max_lines = int(data.get("max_lines", 0))
	session.machine = self
	$EtiquetaPar.text = String(data.get("chalice_label", "PAR"))
	$EtiquetaImpar.text = String(data.get("crucible_label", "IMPAR"))
	$Glifo.text = String(data.get("glyph", "n % 2"))
	connect_console(open_codex)
	new_rules()


func _draw() -> void:
	CribaView.draw_board(self, _gate_open, _round_lit, _filled, _time)


# ------------------------------------------------------------------ esferas

## Esferas nuevas para todas las rondas.
func new_rules() -> void:
	rules = ParityFilter.new(_data.get("rounds", []), _rng)
	_round_lit.fill(false)
	_filled = 0
	_show_round(0, rules.rounds[0])


## Pone las esferas de la ronda en el canal.
func _show_round(index: int, values: Array) -> void:
	for s in _spheres:
		s.queue_free()
	_spheres.clear()
	if _on_gate:
		_on_gate.queue_free()
		_on_gate = null
	_round_shown = index
	for v in values:
		var s := CribaSphere.new()
		s.value = int(v)
		s.font = _font
		s.z_index = 2
		add_child(s)
		_spheres.append(s)
	_layout_spheres(false)


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
	var sphere: CribaSphere = _spheres.pop_front()
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

func _absorb(sphere: CribaSphere, to_chalice: bool) -> void:
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


## Esfera en el lado equivocado: la máquina se traba.
func _wrong(sphere: CribaSphere, to_chalice: bool) -> void:
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
