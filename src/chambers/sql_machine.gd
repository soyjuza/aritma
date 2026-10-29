@tool
## Base de las máquinas que leen consultas SQL. Patrón Template Method: prueba la consulta
## en varias rondas, cada una con sus tablas, y la compara con la respuesta de la sala
## (chambers.json, "answer"). Cada máquina dice qué tablas hay (make_tables) y cómo se ve.
class_name SqlMachine
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
var answer := ""              # la consulta que resuelve la sala
var ordered := false          # true: las filas deben salir en el mismo orden
var tables: Array = []        # las tablas de la ronda que se ve (SqlTable)
var columns: Array = []       # lo que devolvió la consulta en esa ronda
var got: Array = []
var wanted: Array = []        # lo que debía devolver (filas de la respuesta)
var mark := Color(0, 0, 0, 0)

var _bus: EventBus
var _text: Callable
var _data: Dictionary
var _round := 0
var _rng := RandomNumberGenerator.new()
var _font: Font
var _dbs: Array = []          # las tablas de cada ronda


func _ready() -> void:
	_font = load(UIKit.PIXEL_FONT)


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	_bus = bus
	_text = text
	_data = data
	rounds = int(data.get("rounds", 3))
	answer = String(data.get("answer", ""))
	ordered = bool(data.get("ordered", false))
	var seed_value := int(data.get("seed", 0))
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	view_focus = Vector2(0, -30)
	session.title = String(data.get("name", ""))
	session.file_name = String(data.get("file_name", "consulta.sql"))
	session.code = String(data.get("starter_code", ""))
	session.help = data.get("help", [])
	session.write_first = bool(data.get("write_first", false))
	session.set_blocks(data.get("blocks", []))
	session.machine = self
	connect_console(open_codex)
	new_rounds(false)


func status_text() -> String:
	return _text.call("rounds_status", {"round": _round + 1, "of": rounds})


## Las tablas de la ronda i. Cada máquina las inventa.
func make_tables(_i: int) -> Array:
	return []


## Tablas nuevas para las rondas. keep_first deja igual la que se ve.
func new_rounds(keep_first := true) -> void:
	var first: Array = _dbs[0] if keep_first and not _dbs.is_empty() else make_tables(0)
	_dbs = [first]
	for i in range(1, rounds):
		_dbs.append(make_tables(i))
	show_round(0)
	session.tables = _dbs[0]


## La ronda i en la máquina, todavía sin resultado.
func show_round(i: int) -> void:
	_round = i
	tables = _dbs[i] if i < _dbs.size() else []
	columns = []
	got = []
	wanted = []
	mark = Color(0, 0, 0, 0)


## La tabla name de la ronda que se ve.
func table(name: String) -> SqlTable:
	for t: SqlTable in tables:
		if t.name == name:
			return t
	return null


## Los valores de la columna name en lo que devolvió la consulta.
func got_values(name: String) -> Array:
	var at := -1
	for i in columns.size():
		if String(columns[i]).to_lower() == name.to_lower():
			at = i
	return [] if at < 0 else got.map(func(r): return r[at])


# ------------------------------------------------------------------ evaluar (sin dibujar)

func evaluate(source: String, engine: SqlEngine) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	report.success = true
	for i in _dbs.size():
		var result := engine.run(source, _dbs[i])
		if not result.ok:
			report.ok = false
			report.success = false
			report.error = result.error_text()
			return report
		# La consola muestra solo la primera ronda
		if i == 0:
			report.output = SqlEngine.result_lines(result)
		var want := engine.run(answer, _dbs[i])
		assert(want.ok, "La respuesta de la sala no corre: " + want.error)
		var diff := SqlCheck.compare(result, want, ordered)
		report.commands.append({"round": i, "columns": result.columns, "rows": result.rows, "ok": diff.is_empty(), "want_columns": want.columns, "want": want.rows})
		if not diff.is_empty():
			report.success = false
			var prefix: String = _text.call("rounds_prefix", {"round": i + 1}) if _dbs.size() > 1 else ""
			report.message = prefix + String(_text.call(String(diff.key), diff))
			break
	if report.success:
		report.message = String(_data.get("solved_text", ""))
	return report


# ------------------------------------------------------------------ mostrar

func perform(report: CodeMachine.Report) -> void:
	for c: Dictionary in report.commands:
		show_round(c.round)
		await _wait(0.5)
		columns = c.columns
		got = c.rows
		wanted = c.want
		await react(c.ok)
		mark = GOOD if c.ok else BAD
		_bus.publish(GameEvents.MACHINE_ROUND if c.ok else GameEvents.MACHINE_BAD)
		await _wait(0.8)
		if not c.ok:
			# Las rondas ocultas cambian; la que se ve queda igual para corregir con calma
			new_rounds()
			return
	mark_solved()


## Lo que hace la máquina con el resultado de la ronda (cada una lo anima a su modo).
func react(_right: bool) -> void:
	await _wait(0.6)


func mark_solved() -> void:
	mark = GOOD
	super()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _text_center(s: String, at: Vector2, size: int, color: Color) -> void:
	TableSign.text(self, _font, s, at, size, color, true)


## Las tablas de la ronda en tablillas, una al lado de otra, apoyadas en bottom.
## keys: {tabla: columna} marca las filas de esa tabla que trajo la consulta.
func _draw_tables(keys: Dictionary, bottom: float, size := 6, gap := 8.0) -> void:
	var sizes: Array = tables.map(func(t): return TableSign.measure(_font, t.columns, t.rows, size, t.name))
	var total := gap * (tables.size() - 1)
	for s: Vector2 in sizes:
		total += s.x
	var x := -total / 2.0
	for i in tables.size():
		var t: SqlTable = tables[i]
		var marks := {}
		if keys.has(t.name):
			for r in t.rows_with(keys[t.name], got_values(keys[t.name])):
				marks[r] = mark if mark.a > 0.0 else CYAN
		TableSign.draw(self, _font, t.columns, t.rows, Vector2(x, bottom - sizes[i].y), size, t.name, marks)
		x += sizes[i].x + gap


## Un nombre de pool para cada fila, sin repetir.
func _names(pool: Array, count: int) -> Array:
	var copy := pool.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy.slice(0, count)


## Números distintos entre lo y hi.
func _distinct(count: int, lo: int, hi: int) -> Array:
	var out: Array = []
	while out.size() < count:
		var v := _rng.randi_range(lo, hi)
		if not v in out:
			out.append(v)
	return out
