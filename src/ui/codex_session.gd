## Lo que una terminal le pasa al Códice.
class_name CodexSession
extends RefCounted

var title := ""
var file_name := "programa.py"
var code := ""
var max_lines := 0    # 0 = sin límite
var help: Array = []               # [["avanzar(n=1)", "avanza n casillas"], ...]
var api_factory: Callable
var on_result: Callable
var max_steps := 200000
var close_after_run := false
var machine: CodeMachine = null
var log: Array = []    # lo que mostraba la consola


## Líneas que cuentan (sin vacías ni comentarios).
static func count_lines(source: String) -> int:
	var n := 0
	for line in source.split("\n"):
		var t := line.strip_edges()
		if t != "" and not t.begins_with("#"):
			n += 1
	return n


var blocks: Array = []    # piezas para armar el programa
var placed: Array = []    # [[pieza, sangría], ...]
var use_blocks := false
var goal: Array = []    # los comentarios del código inicial, para el modo bloques


## Piezas revueltas. Si hay piezas, el Códice abre con bloques.
func set_blocks(lines: Array) -> void:
	var clean := lines.map(func(l): return String(l).strip_edges())
	blocks = clean.duplicate()
	while blocks.size() > 1 and blocks == clean:
		blocks.shuffle()
	placed.clear()
	use_blocks = not blocks.is_empty()
	goal = Array(code.split("\n")).filter(func(l): return l.begins_with("#")).map(func(l): return l.trim_prefix("#").strip_edges())


## Piezas que siguen en la bandeja.
func free_pieces() -> Array:
	var used := placed.map(func(p): return p[0])
	return range(blocks.size()).filter(func(i): return not used.has(i))


## Programa armado con las piezas.
func blocks_source() -> String:
	var out := ""
	for p in placed:
		out += "    ".repeat(int(p[1])) + String(blocks[p[0]]) + "\n"
	return out


## Lo que se guarda de los bloques.
func blocks_state() -> Dictionary:
	return {"blocks": blocks, "placed": placed, "use_blocks": use_blocks}


func restore_blocks(state: Dictionary) -> void:
	if state.has("blocks") and (state.blocks as Array).size() == blocks.size():
		blocks = state.blocks
		placed = state.get("placed", [])
		use_blocks = bool(state.get("use_blocks", use_blocks))
