@tool
## La Compuerta (Sala 1). Sube al nivel del sensor + add, en varias rondas.
class_name LockMachine
extends CodeMachine

const OUTLINE := Color("14181c")
const STONE := Color("4a4560")
const STONE_LIGHT := Color("6e6790")
const STONE_DARK := Color("2c2840")
const BRONZE := Color("b48a4e")
const BRONZE_DARK := Color("7a5a2e")
const CYAN := Color("3fe0ff")
const GOOD := Color("6be38b")
const BAD := Color("ff5a4e")
const GOLD := Color("ffd27a")
const TOP := 12.0                              # nivel más alto del medidor
const HOLE := Rect2(-26, -88, 52, 88)          # hueco de la compuerta

var rounds := 3
var add := 3
var sensor := -1           # número en el sensor (-1 = apagado)
var level := 0.0           # altura de la compuerta, en niveles
var mark := Color(0, 0, 0, 0)

var _bus: EventBus
var _text: Callable
var _round := 0
var _rng := RandomNumberGenerator.new()
var _font: Font

@onready var _light: PointLight2D = $Luz


func _ready() -> void:
	_font = load(UIKit.PIXEL_FONT)


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	_bus = bus
	_text = text
	rounds = int(data.get("rounds", 3))
	add = int(data.get("add", 3))
	_rng.randomize()
	view_focus = Vector2(0, -50)
	session.title = String(data.get("name", ""))
	session.file_name = String(data.get("file_name", "compuerta.py"))
	session.code = String(data.get("starter_code", ""))
	session.help = data.get("help", [])
	session.set_blocks(data.get("blocks", []))
	session.machine = self
	connect_console(open_codex)


func status_text() -> String:
	return _text.call("lock_status", {"round": _round + 1, "of": rounds})


func mark_solved() -> void:
	level = TOP
	mark = GOOD
	super()


# ------------------------------------------------------------------ evaluar (sin dibujar)

func evaluate(source: String, sandbox: ScriptSandbox) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	report.success = true
	for i in rounds:
		var value := _rng.randi_range(1, 9)
		var raised := [-1]
		var api := {"sensor": SensorAdapter.new(value), "compuerta": LockAdapter.new(func(n): raised[0] = n)}
		var result := sandbox.run(source, api, session.max_steps)
		# La consola muestra solo la primera ronda
		if i == 0:
			report.output = result.output
		if not result.ok:
			report.ok = false
			report.error = result.error_text()
			return report
		report.commands.append({"sensor": value, "raised": raised[0]})
		if report.success and raised[0] != value + add:
			report.success = false
			var info := {"round": i + 1, "sensor": value, "raised": raised[0], "want": value + add}
			report.message = _text.call("lock_still" if raised[0] < 0 else "lock_wrong", info)
	if report.success:
		report.message = _text.call("lock_solved", {})
	return report


# ------------------------------------------------------------------ mostrar

func perform(report: CodeMachine.Report) -> void:
	for i in report.commands.size():
		var c: Dictionary = report.commands[i]
		_round = i
		sensor = c.sensor
		mark = Color(0, 0, 0, 0)
		level = 0.0
		await get_tree().create_timer(0.4).timeout
		var target := clampf(float(c.raised), 0.0, TOP + 2.0)
		var t := create_tween()
		t.tween_property(self, "level", target, 0.3 + 0.05 * target)
		await t.finished
		var ok: bool = c.raised == c.sensor + add
		mark = GOOD if ok else BAD
		_bus.publish(GameEvents.MACHINE_ROUND if ok else GameEvents.MACHINE_BAD)
		await get_tree().create_timer(0.6).timeout
		if not ok:
			return
	var glow := create_tween()
	glow.tween_property(self, "level", TOP, 0.4)
	glow.parallel().tween_property(_light, "energy", 1.4, 0.4)
	await glow.finished
	mark_solved()


# ------------------------------------------------------------------ dibujo

func _draw() -> void:
	# Fondo del hueco
	draw_rect(HOLE, Color("0b0e14"))
	# La reja sube según el nivel
	var lift := HOLE.size.y * clampf(level / TOP, 0.0, 1.0)
	var gate := Rect2(HOLE.position.x, HOLE.position.y, HOLE.size.x, HOLE.size.y - lift)
	if gate.size.y > 0.5:
		for x in range(int(gate.position.x) + 3, int(gate.end.x), 7):
			draw_rect(Rect2(x, gate.position.y, 3, gate.size.y), BRONZE)
			draw_rect(Rect2(x + 2, gate.position.y, 1, gate.size.y), BRONZE_DARK)
		draw_rect(Rect2(gate.position.x, gate.end.y - 4, gate.size.x, 4), BRONZE_DARK)
	# Pilares y dintel
	for px in [-40.0, 26.0]:
		var pillar := Rect2(px, -96, 14, 96)
		draw_rect(pillar.grow(1), OUTLINE)
		draw_rect(pillar, STONE)
		draw_rect(Rect2(pillar.position, Vector2(3, pillar.size.y)), STONE_LIGHT)
		draw_rect(Rect2(pillar.end.x - 3, pillar.position.y, 3, pillar.size.y), STONE_DARK)
	var lintel := Rect2(-44, -108, 88, 14)
	draw_rect(lintel.grow(1), OUTLINE)
	draw_rect(lintel, BRONZE)
	_text_center("SENSOR + %d" % add, Vector2(0, -97), 11, OUTLINE)
	# Medidor en el pilar derecho
	for n in int(TOP) + 1:
		var y := -4.0 - (HOLE.size.y - 8.0) * n / TOP
		draw_rect(Rect2(30, y, 6 if n % 3 == 0 else 3, 1), CYAN.darkened(0.3))
	var my := -4.0 - (HOLE.size.y - 8.0) * clampf(level / TOP, 0.0, 1.0)
	draw_rect(Rect2(28, my - 1.5, 10, 3), mark if mark.a > 0.0 else GOLD)
	# Sensor en el pilar izquierdo
	var box := Rect2(-58, -62, 22, 18)
	draw_rect(box.grow(1), OUTLINE)
	draw_rect(box, Color("101820"))
	if sensor >= 0:
		_text_center(str(sensor), box.get_center() + Vector2(0, 6), 16, CYAN)
	if mark.a > 0.0:
		_text_center(str(int(round(level))), Vector2(46, my + 4), 12, mark)


func _text_center(s: String, at: Vector2, size: int, color: Color) -> void:
	if _font == null:
		return
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(_font, at - Vector2(w / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
