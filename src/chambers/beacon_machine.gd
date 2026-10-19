@tool
## El Faro de Celdas (Sala 3): un obelisco de piedra con un cristal arriba y, en su cara, un
## tablero grabado de 8×8. Enciende el tablero del Vórtice cuando el programa del jugador define
## bien dentro(x, y): True si la casilla (x, y) está dentro del tablero de 8×8 y False si no.
## (Con esa regla el juego calcula las vecinas de cada baldosa y sus números.)
## Se prueba con las 4 esquinas, el centro y casillas de justo afuera elegidas al azar (así no
## sirve escribir las respuestas a mano). perform() muestra cada prueba en el tablero grabado:
## la casilla probada en verde (bien) o rojo (mal).
class_name BeaconMachine
extends CodeMachine

const OUTLINE := Color("14181c")
const STONE := Color("4a4560")
const STONE_LIGHT := Color("6e6790")
const STONE_DARK := Color("2c2840")
const BRONZE := Color("b48a4e")
const CYAN := Color("3fe0ff")
const GOLD := Color("ffc857")
const GREEN := Color("6be38b")
const RED := Color("ff5a4e")
const MINI := 2.0                  # tamaño de cada casilla del tablero grabado (px)
const MINI_ORIGIN := Vector2(-8, -36)
const NO_CELL := Vector2i(-99, -99)

var cols := 8
var rows := 8
var cases: Array[Vector2i] = []
var lit := 0.0                      # 0..1: el cristal encendido

var _bus: EventBus
var _data: Dictionary
var _text: Callable
var _rng := RandomNumberGenerator.new()
var _shown_cell := NO_CELL
var _shown_ok := true

@onready var _light: PointLight2D = $Luz


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	_bus = bus
	_data = data
	_text = text
	var board: Dictionary = data.get("board", {})
	cols = int(board.get("cols", 8))
	rows = int(board.get("rows", 8))
	var seed_value := int(data.get("seed", 0))
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	view_focus = Vector2(0, -30)
	session.title = String(data.get("name", ""))
	session.file_name = String(data.get("file_name", "faro.py"))
	session.code = String(data.get("starter_code", ""))
	session.help = data.get("help", [])
	session.machine = self
	connect_console(open_codex)
	new_cases()


## Las casillas de prueba: las 4 esquinas, una de cada borde y una del centro (adentro) y,
## justo afuera, una de cada lado y una esquina (al azar). El orden también cambia.
func new_cases() -> void:
	cases = [Vector2i(0, 0), Vector2i(cols - 1, 0), Vector2i(0, rows - 1), Vector2i(cols - 1, rows - 1)]
	cases.append(Vector2i(_rng.randi_range(1, cols - 2), _rng.randi_range(1, rows - 2)))
	cases.append(Vector2i(_rng.randi_range(0, cols - 1), -1))
	cases.append(Vector2i(_rng.randi_range(0, cols - 1), rows))
	cases.append(Vector2i(-1, _rng.randi_range(0, rows - 1)))
	cases.append(Vector2i(cols, _rng.randi_range(0, rows - 1)))
	cases.append([Vector2i(-1, -1), Vector2i(cols, -1), Vector2i(-1, rows), Vector2i(cols, rows)][_rng.randi_range(0, 3)])
	for i in range(cases.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := cases[i]
		cases[i] = cases[j]
		cases[j] = tmp


func inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows


## Revisa lo que devolvió dentro(x, y). Devuelve "" si está bien o el motivo del error.
func check(c: Vector2i, value) -> String:
	var args := {"x": c.x, "y": c.y, "got": ScriptContext.to_text(value)}
	if typeof(value) != TYPE_BOOL:
		return _text.call("beacon_bad_shape", args)
	if value != inside(c):
		return _text.call("beacon_wrong_in" if inside(c) else "beacon_wrong_out", args)
	return ""


func status_text() -> String:
	return _text.call("beacon_status", {})


# ------------------------------------------------------------------ evaluar (sin dibujar)

func evaluate(source: String, sandbox: ScriptSandbox) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	var program := sandbox.run(source, {}, session.max_steps)
	report.output = program.output
	if not program.ok:
		report.ok = false
		report.error = program.error_text()
		return report
	if not program.context.globals.get("dentro") is ScriptCallable:
		report.ok = false
		report.error = _text.call("beacon_no_function", {})
		return report
	report.success = true
	for c in cases:
		var answer := sandbox.call_function(program, "dentro", [c.x, c.y])
		var problem := ""
		if not answer[0]:
			problem = _text.call("beacon_error", {"x": c.x, "y": c.y, "error": answer[1]})
		else:
			problem = check(c, answer[1])
		report.commands.append({"cell": c, "ok": problem == ""})
		if problem != "":
			report.success = false
			report.message = problem
			break
	if report.success:
		report.message = _text.call("beacon_solved", {})
	return report


# ------------------------------------------------------------------ mostrar

func perform(report: CodeMachine.Report) -> void:
	for step: Dictionary in report.commands:
		_shown_cell = step.cell
		_shown_ok = step.ok
		_bus.publish(GameEvents.MACHINE_GOOD if step.ok else GameEvents.MACHINE_BAD)
		await _wait(0.28 if step.ok else 1.2)
	_shown_cell = NO_CELL
	if report.success:
		_bus.publish(GameEvents.MACHINE_ROUND)
		var t := create_tween()
		t.tween_property(self, "lit", 1.0, 0.8)
		t.parallel().tween_property(_light, "energy", 1.6, 0.8)
		await t.finished
		mark_solved()
	else:
		new_cases()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


# ------------------------------------------------------------------ dibujo

func _draw() -> void:
	# El obelisco
	var body := Rect2(-13, -46, 26, 46)
	draw_rect(body.grow(1), OUTLINE)
	draw_rect(body, STONE)
	draw_rect(Rect2(body.position, Vector2(3, body.size.y)), STONE_LIGHT)
	draw_rect(Rect2(body.end.x - 3, body.position.y, 3, body.size.y), STONE_DARK)
	draw_rect(Rect2(-14, -6, 28, 4), BRONZE)
	draw_rect(Rect2(-14, -42, 28, 3), BRONZE)
	# El cristal
	var crystal := PackedVector2Array([Vector2(0, -60), Vector2(6, -51), Vector2(0, -44), Vector2(-6, -51)])
	draw_colored_polygon(crystal, Color("1d3a48").lerp(CYAN, lit))
	draw_polyline(crystal + PackedVector2Array([crystal[0]]), OUTLINE, 1.0)
	draw_line(Vector2(-2, -55), Vector2(0, -57), Color(1, 1, 1, 0.5 + 0.5 * lit), 1.0)
	# El tablero grabado (8×8) con un marco de una casilla: ahí se ven las pruebas de afuera
	var size := Vector2(cols, rows) * MINI
	draw_rect(Rect2(MINI_ORIGIN - Vector2(1, 1) * (MINI + 1), size + Vector2(2, 2) * (MINI + 1)), STONE_DARK.darkened(0.3))
	draw_rect(Rect2(MINI_ORIGIN - Vector2(1, 1), size + Vector2(2, 2)), OUTLINE)
	for y in rows:
		for x in cols:
			draw_rect(Rect2(MINI_ORIGIN + Vector2(x, y) * MINI, Vector2(MINI - 0.5, MINI - 0.5)), STONE_DARK.lerp(CYAN.darkened(0.5), lit))
	if _shown_cell != NO_CELL:
		draw_rect(Rect2(MINI_ORIGIN + Vector2(_shown_cell) * MINI, Vector2(MINI - 0.5, MINI - 0.5)), GREEN if _shown_ok else RED)
