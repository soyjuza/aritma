@tool
## La Criba (capítulo 3, OR). Patrón Command: perform() ejecuta las órdenes (FilterCommand)
## que arma SphereSorter: al cáliz caen las esferas que trajo la consulta; las demás, al crisol.
class_name CribaMachine
extends SqlMachine

const CHANNEL_Y := -44.0
const GATE := Vector2(30, -44)
const SLOT_GAP := 15.0
const VISIBLE_SLOTS := 7
const CHALICE := Vector2(-4, -6)
const CRUCIBLE := Vector2(64, -6)
const SPLIT := Vector2(30, -26)

const STONE_DARK := Color("27342e")
const STONE := Color("3e5246")
const STONE_LIGHT := Color("6a8070")
const BRONZE := Color("b48a4e")
const BRONZE_DARK := Color("6e5232")
const GLASS := Color(0.62, 0.9, 1.0, 0.22)
const RED := Color("ff5a4e")

var kit: TileKit
var round_count := 3
var limit := 50

var _spheres: Array[CribaSphere] = []
var _on_gate: CribaSphere = null
var _gate_open := 0.0    # -1 cáliz, 1 crisol
var _round_lit: Array = [false, false, false]
var _round_shown := 0
var _speed := 1.0
var _filled := 0

@onready var _hopper_label: Label = $Tolva
@onready var _gate_number: Label = $NumeroCompuerta
@onready var _chalice_light: PointLight2D = $LuzCaliz
@onready var _crucible_light: PointLight2D = $LuzCrisol


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	limit = int(data.get("limit", 50))
	round_count = int(data.get("rounds", 3))
	_round_lit.resize(round_count)
	_round_lit.fill(false)
	super(bus, data, text, open_codex)
	view_focus = Vector2(-6, -28)
	$EtiquetaPar.text = String(data.get("chalice_label", "CÁLIZ"))
	$EtiquetaImpar.text = String(data.get("crucible_label", "CRISOL"))
	$Glifo.text = String(data.get("glyph", ""))


func _draw() -> void:
	CribaView.draw_board(self, _gate_open, _round_lit, _filled, _time)
	var t := table("esferas")
	if t:
		var marks := {}
		for r in t.rows_with("numero", got_values("numero")):
			marks[r] = mark if mark.a > 0.0 else CYAN
		var size := TableSign.measure(_font, t.columns, t.rows, 6, t.name)
		TableSign.draw(self, _font, t.columns, t.rows, Vector2(-112 - size.x, -16 - size.y), 6, t.name, marks)


# ------------------------------------------------------------------ esferas

## Esferas de la ronda: siempre hay doradas chicas, grises grandes y grises chicas.
func make_tables(i: int) -> Array:
	var count := _rng.randi_range(6, 8)
	var numbers := _distinct(count, 1, 99)
	var colors: Array = []
	for k in count:
		colors.append("oro" if _rng.randf() < 0.4 else "gris")
	numbers[0] = _rng.randi_range(1, limit)
	colors[0] = "oro"
	numbers[1] = _rng.randi_range(limit + 1, 99)
	colors[1] = "gris"
	numbers[2] = _rng.randi_range(1, limit)
	colors[2] = "gris"
	var rows: Array = []
	for k in count:
		if numbers.count(numbers[k]) > 1:
			numbers[k] = _free_number(numbers, numbers[k] > limit)
		rows.append([numbers[k], colors[k]])
	rows.shuffle()
	return [SqlTable.new("esferas", ["numero", "color"], rows)]


func _free_number(used: Array, big: bool) -> int:
	var v := _rng.randi_range(limit + 1, 99) if big else _rng.randi_range(1, limit)
	while v in used:
		v = _rng.randi_range(limit + 1, 99) if big else _rng.randi_range(1, limit)
	return v


func new_rounds(keep_first := true) -> void:
	super(keep_first)
	_round_lit.fill(false)
	_filled = 0
	if is_inside_tree():
		_show_round(0, tables[0].rows if not tables.is_empty() else [])


## Pone las esferas de la ronda en el canal. rows: [[numero, color], ...]
func _show_round(index: int, rows: Array) -> void:
	for s in _spheres:
		s.queue_free()
	_spheres.clear()
	if _on_gate:
		_on_gate.queue_free()
		_on_gate = null
	_round_shown = index
	for r in rows:
		var s := CribaSphere.new()
		s.value = int(r[0])
		s.gold = String(r[1]) == "oro"
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

## Corre la consulta como cualquier máquina y arma las órdenes de cada esfera.
func evaluate(source: String, engine: SqlEngine) -> CodeMachine.Report:
	var report := super(source, engine)
	if not report.ok:
		return report
	var sorter := SphereSorter.new()
	for c: Dictionary in report.commands:
		var rows: Array = (_dbs[c.round][0] as SqlTable).rows
		var chosen := _numbers(c.columns, c.rows)
		var wanted := _numbers(c.want_columns, c.want)
		if not sorter.add_round(c.round, rows, chosen, wanted, c.ok):
			break
	report.commands = sorter.commands
	return report


## Los números de la columna numero de un resultado.
static func _numbers(names: Array, rows: Array) -> Array:
	var at := names.map(func(n): return String(n).to_lower()).find("numero")
	return [] if at < 0 else rows.map(func(r): return SqlEngine.show(r[at]))


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
		mark = BAD
		await _wait(0.6)
		new_rounds()


func load_round(index: int, rows: Array) -> void:
	_speed = float((_data.get("playback_speed", [1.0, 1.8, 2.6]) as Array)[mini(index, 2)])
	show_round(index)
	if index != _round_shown or _spheres.size() != rows.size():
		_show_round(index, rows)
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
	var smoke := kit.particles(self, SPLIT, "Smoke", 14, 1.2)
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
		var sparks := kit.particles(self, CRUCIBLE + Vector2(0, -14), "Fire", 6, 0.5)
		sparks.gravity = Vector2(0, -40)
		sparks.emitting = true
		get_tree().create_timer(0.8).timeout.connect(sparks.queue_free)


## Esfera en el lado equivocado: la máquina se traba.
func _wrong(sphere: CribaSphere, to_chalice: bool) -> void:
	_bus.publish(GameEvents.MACHINE_BAD)
	sphere.tint = RED
	sphere.queue_redraw()
	var sparks := kit.particles(self, sphere.position, "Spark", 18, 0.7)
	sparks.emitting = true
	var smoke := kit.particles(self, (CHALICE if to_chalice else CRUCIBLE) + Vector2(0, -10), "Smoke", 10, 1.2)
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

