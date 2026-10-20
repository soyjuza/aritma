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
