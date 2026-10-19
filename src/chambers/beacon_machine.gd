@tool
## El Faro de Celdas (Sala 3): un obelisco de piedra con un cristal arriba y, en su cara, un
## tablero grabado de 8×8. Enciende el tablero del Vórtice cuando el programa del jugador define
## bien vecinas(x, y): la lista de casillas que rodean a (x, y) sin salirse del tablero.
## El Códice trae alrededor(x, y), las 8 casillas de alrededor aunque se salgan: el jugador
## solo tiene que quedarse con las que están dentro.
## Se prueba con las 4 esquinas, un borde de cada lado y casillas del centro elegidas al azar
## (así no sirve escribir las respuestas a mano). perform() muestra cada prueba en el tablero
## grabado: la casilla probada en dorado y lo que devolvió en verde (bien) o rojo (mal).
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

var cols := 8
var rows := 8
var cases: Array[Vector2i] = []
var lit := 0.0                      # 0..1: el cristal encendido

var _bus: EventBus
var _data: Dictionary
var _text: Callable
var _rng := RandomNumberGenerator.new()
var _shown_cell := Vector2i(-1, -1)
var _shown_answer: Array = []
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


## Las casillas de prueba: las 4 esquinas, una de cada borde y 3 del centro (al azar).
func new_cases() -> void:
	cases = [Vector2i(0, 0), Vector2i(cols - 1, 0), Vector2i(0, rows - 1), Vector2i(cols - 1, rows - 1)]
	cases.append(Vector2i(_rng.randi_range(1, cols - 2), 0))
	cases.append(Vector2i(_rng.randi_range(1, cols - 2), rows - 1))
	cases.append(Vector2i(0, _rng.randi_range(1, rows - 2)))
	cases.append(Vector2i(cols - 1, _rng.randi_range(1, rows - 2)))
	for i in 3:
		cases.append(Vector2i(_rng.randi_range(1, cols - 2), _rng.randi_range(1, rows - 2)))
	# El orden también cambia
	for i in range(cases.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := cases[i]
		cases[i] = cases[j]
		cases[j] = tmp


## Las vecinas correctas de una casilla (para comparar con lo que devolvió el programa).
func expected(c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var n := c + Vector2i(dx, dy)
			if n != c and n.x >= 0 and n.y >= 0 and n.x < cols and n.y < rows:
				out.append(n)
	return out


## Revisa lo que devolvió vecinas(x, y). Devuelve "" si está bien o el motivo del error.
func check(c: Vector2i, value) -> String:
	var args := {"x": c.x, "y": c.y, "got": ScriptContext.to_text(value)}
	if typeof(value) != TYPE_ARRAY:
		return _text.call("beacon_bad_shape", args)
	var seen := {}
	for item in value:
		if typeof(item) != TYPE_ARRAY or item.size() != 2 or typeof(item[0]) != TYPE_INT or typeof(item[1]) != TYPE_INT:
			return _text.call("beacon_bad_shape", args)
		var n := Vector2i(item[0], item[1])
		args.cell = "[%d, %d]" % [n.x, n.y]
		if seen.has(n):
			return _text.call("beacon_repeated", args)
		seen[n] = true
		if n == c:
			return _text.call("beacon_itself", args)
		if n.x < 0 or n.y < 0 or n.x >= cols or n.y >= rows:
			return _text.call("beacon_outside", args)
		if absi(n.x - c.x) > 1 or absi(n.y - c.y) > 1:
			return _text.call("beacon_not_neighbor", args)
	for n in expected(c):
		if not seen.has(n):
			args.cell = "[%d, %d]" % [n.x, n.y]
			return _text.call("beacon_missing", args)
	return ""


func status_text() -> String:
	return _text.call("beacon_status", {})


# ------------------------------------------------------------------ evaluar (sin dibujar)

func evaluate(source: String, sandbox: ScriptSandbox) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	var program := sandbox.run(source, {"alrededor": HostFunction.new("alrededor", _around, 2, 2)}, session.max_steps)
	report.output = program.output
	if not program.ok:
		report.ok = false
		report.error = program.error_text()
		return report
	if not program.context.globals.get("vecinas") is ScriptCallable:
		report.ok = false
		report.error = _text.call("beacon_no_function", {})
		return report
	report.success = true
	for c in cases:
		var answer := sandbox.call_function(program, "vecinas", [c.x, c.y])
		var problem := ""
		if not answer[0]:
			problem = _text.call("beacon_error", {"x": c.x, "y": c.y, "error": answer[1]})
		else:
			problem = check(c, answer[1])
		report.commands.append({"cell": c, "answer": answer[1] if answer[0] and typeof(answer[1]) == TYPE_ARRAY else [], "ok": problem == ""})
		if problem != "":
			report.success = false
			report.message = problem
			break
	if report.success:
		report.message = _text.call("beacon_solved", {})
	return report


## alrededor(x, y) en el Códice: las 8 casillas que rodean a (x, y), también las de afuera.
func _around(ctx: ScriptContext, args: Array, line: int):
	if typeof(args[0]) != TYPE_INT or typeof(args[1]) != TYPE_INT:
		ctx.fail(_text.call("beacon_around_ints", {}), line)
		return null
	var out: Array = []
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx != 0 or dy != 0:
				out.append([args[0] + dx, args[1] + dy])
	return out


# ------------------------------------------------------------------ mostrar

func perform(report: CodeMachine.Report) -> void:
	for step: Dictionary in report.commands:
		_shown_cell = step.cell
		_shown_answer = step.answer
		_shown_ok = step.ok
		_bus.publish(GameEvents.MACHINE_GOOD if step.ok else GameEvents.MACHINE_BAD)
		await _wait(0.28 if step.ok else 1.2)
	_shown_cell = Vector2i(-1, -1)
	_shown_answer = []
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
	# El tablero grabado (8×8)
	var size := Vector2(cols, rows) * MINI
	draw_rect(Rect2(MINI_ORIGIN - Vector2(1, 1), size + Vector2(2, 2)), OUTLINE)
	for y in rows:
		for x in cols:
			var color := STONE_DARK.lerp(CYAN.darkened(0.5), lit)
			if Vector2i(x, y) == _shown_cell:
				color = GOLD
			draw_rect(Rect2(MINI_ORIGIN + Vector2(x, y) * MINI, Vector2(MINI - 0.5, MINI - 0.5)), color)
	for item in _shown_answer:
		if typeof(item) == TYPE_ARRAY and item.size() == 2 and typeof(item[0]) == TYPE_INT and typeof(item[1]) == TYPE_INT:
			var at := MINI_ORIGIN + Vector2(item[0], item[1]) * MINI
			if Rect2(MINI_ORIGIN, size).has_point(at):
				draw_rect(Rect2(at, Vector2(MINI - 0.5, MINI - 0.5)), GREEN if _shown_ok else RED)
