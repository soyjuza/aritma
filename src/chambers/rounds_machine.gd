@tool
## Base de las máquinas del Bosque. Patrón Template Method: corre el programa
## en varias rondas; cada máquina dice qué hay en la ronda y si salió bien.
class_name RoundsMachine
extends CodeMachine

const OUTLINE := Color("14181c")
const WOOD := Color("8a5a32")
const WOOD_DARK := Color("5a3820")
const LEAF := Color("5fae4a")
const CYAN := Color("3fe0ff")
const GOOD := Color("6be38b")
const BAD := Color("ff5a4e")
const GOLD := Color("ffd27a")

var rounds := 3
var value = -1                # lo de la ronda que se ve: número, lista... (-1 = nada)
var did := ""                 # lo que hizo el programa en la ronda
var mark := Color(0, 0, 0, 0)

var _bus: EventBus
var _text: Callable
var _data: Dictionary
var _round := 0
var _rng := RandomNumberGenerator.new()
var _font: Font


func _ready() -> void:
	_font = load(UIKit.PIXEL_FONT)


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	_bus = bus
	_text = text
	_data = data
	rounds = int(data.get("rounds", 3))
	_rng.randomize()
	view_focus = Vector2(0, -30)
	session.title = String(data.get("name", ""))
	session.file_name = String(data.get("file_name", "programa.py"))
	session.code = String(data.get("starter_code", ""))
	session.help = data.get("help", [])
	session.set_blocks(data.get("blocks", []))
	session.machine = self
	connect_console(open_codex)


func status_text() -> String:
	return _text.call("rounds_status", {"round": _round + 1, "of": rounds})


## Los números de las rondas. Cada máquina los elige.
func make_values() -> Array:
	return []


## Los objetos del Códice para una ronda. record(texto) anota lo que hizo.
func api_for(_value, _record: Callable) -> Dictionary:
	return {}


## Lo que debía hacer el programa con ese número ("" = nada).
func wanted(_value) -> String:
	return ""


## Cómo se escribe lo que hizo el programa en la ronda.
func summary(done: Array) -> String:
	return " y ".join(done)


## Después de correr el programa (las máquinas con funciones la llaman aquí). "" = bien, o el error.
func after_run(_result: ScriptSandbox.Result, _sandbox: ScriptSandbox, _value, _record: Callable) -> String:
	return ""


## Cómo se muestra el número de la ronda en los mensajes.
func value_text(v) -> String:
	return str(v)


# ------------------------------------------------------------------ evaluar (sin dibujar)

func evaluate(source: String, sandbox: ScriptSandbox) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	report.success = true
	var values := make_values()
	for i in values.size():
		var done: Array = []
		var result := sandbox.run(source, api_for(values[i], func(what): done.append(what)), session.max_steps)
		if i == 0:
			report.output = result.output
		if not result.ok:
			report.ok = false
			report.error = result.error_text()
			return report
		var problem := after_run(result, sandbox, values[i], func(what): done.append(what))
		if problem != "":
			report.ok = false
			report.error = problem
			return report
		var got := summary(done)
		report.commands.append({"value": values[i], "did": got})
		if report.success and got != wanted(values[i]):
			report.success = false
			report.message = _text.call(String(_data.get("wrong_key", "rounds_wrong")), {
				"round": i + 1, "n": value_text(values[i]),
				"did": got if got != "" else _text.call("rounds_nothing", {}),
				"want": wanted(values[i]) if wanted(values[i]) != "" else _text.call("rounds_nothing", {}),
			})
	if report.success:
		report.message = String(_data.get("solved_text", ""))
	return report


# ------------------------------------------------------------------ mostrar

func perform(report: CodeMachine.Report) -> void:
	for i in report.commands.size():
		var c: Dictionary = report.commands[i]
		_round = i
		value = c.value
		did = ""
		mark = Color(0, 0, 0, 0)
		await get_tree().create_timer(0.5).timeout
		did = c.did
		var ok: bool = c.did == wanted(c.value)
		mark = GOOD if ok else BAD
		_bus.publish(GameEvents.MACHINE_ROUND if ok else GameEvents.MACHINE_BAD)
		await get_tree().create_timer(0.8).timeout
		if not ok:
			return
	mark_solved()


func mark_solved() -> void:
	mark = GOOD
	super()


func _text_center(s: String, at: Vector2, size: int, color: Color) -> void:
	if _font == null:
		return
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string_outline(_font, at - Vector2(w / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, OUTLINE)
	draw_string(_font, at - Vector2(w / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## Cartel con el número de la ronda.
func _draw_sign(at: Vector2) -> void:
	var box := Rect2(at - Vector2(13, 10), Vector2(26, 20))
	draw_rect(Rect2(at.x - 1.5, at.y + 10, 3, 12), WOOD_DARK)
	draw_rect(box.grow(1), OUTLINE)
	draw_rect(box, WOOD)
	draw_rect(box.grow(-2), Color("2a1c10"))
	if value >= 0:
		_text_center(str(value), at + Vector2(0, 6), 16, mark if mark.a > 0.0 else CYAN)
