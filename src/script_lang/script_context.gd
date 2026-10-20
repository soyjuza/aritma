## Estado de una ejecución: variables, salida, errores y límite de pasos.
class_name ScriptContext
extends RefCounted

const MAX_CALL_DEPTH := 60

var globals: Dictionary = {}
var flow := ""              # "", "return", "break", "continue"
var return_value = null
var error := ""
var error_line := 0
var output: Array[String] = []
var steps := 0
var max_steps := 200000

var _frames: Array[Dictionary] = []


func failed() -> bool:
	return error != ""


func fail(message: String, line: int) -> void:
	if error == "":
		error = message
		error_line = line


## Cuenta un paso. false si se pasó del límite.
func tick(line: int) -> bool:
	steps += 1
	if steps > max_steps:
		fail(ScriptMessages.text("programa_tardo_demasiado_hay_while"), line)
		return false
	return true


func push_frame(locals: Dictionary) -> bool:
	if _frames.size() >= MAX_CALL_DEPTH:
		return false
	_frames.append(locals)
	return true


func pop_frame() -> void:
	_frames.pop_back()


func has_name(name: String) -> bool:
	return (not _frames.is_empty() and _frames[-1].has(name)) or globals.has(name)


func lookup(name: String, line: int):
	if not _frames.is_empty() and _frames[-1].has(name):
		return _frames[-1][name]
	if globals.has(name):
		return globals[name]
	var hint := suggest(name)
	fail(ScriptMessages.text("no_conozco") % [name, (ScriptMessages.text("quisiste_decir") % hint) if hint != "" else ""], line)
	return null


func assign(name: String, value) -> void:
	if not _frames.is_empty():
		_frames[-1][name] = value
	else:
		globals[name] = value


func print_line(text: String) -> void:
	output.append(text)


## El nombre más parecido, para los errores.
func suggest(name: String) -> String:
	var best := ""
	var best_score := 0.0
	var names: Array = globals.keys()
	if not _frames.is_empty():
		names.append_array(_frames[-1].keys())
	for candidate in names:
		var score := String(candidate).similarity(name)
		if score > best_score:
			best_score = score
			best = candidate
	return best if best_score >= 0.5 else ""


# ------------------------------------------------------------------ valores al estilo Python

static func truthy(v) -> bool:
	if v == null:
		return false
	match typeof(v):
		TYPE_BOOL:
			return v
		TYPE_INT, TYPE_FLOAT:
			return v != 0
		TYPE_STRING:
			return v != ""
		TYPE_ARRAY:
			return not v.is_empty()
	return true


static func to_text(v) -> String:
	if v == null:
		return "None"
	match typeof(v):
		TYPE_BOOL:
			return "True" if v else "False"
		TYPE_FLOAT:
			if is_equal_approx(v, round(v)) and absf(v) < 1e15:
				return "%.1f" % v
			return str(v)
		TYPE_ARRAY:
			var parts: Array = []
			for item in v:
				parts.append(repr(item))
			return "[" + ", ".join(parts) + "]"
	if v is ScriptObject:
		return v.describe()
	if v is ScriptCallable:
		return "<función %s>" % v.name
	return str(v)


static func repr(v) -> String:
	return "'%s'" % v if typeof(v) == TYPE_STRING else to_text(v)


static func type_name(v) -> String:
	if v == null:
		return "None"
	match typeof(v):
		TYPE_BOOL:
			return "bool"
		TYPE_INT:
			return "int"
		TYPE_FLOAT:
			return "float"
		TYPE_STRING:
			return "str"
		TYPE_ARRAY:
			return "list"
	if v is ScriptCallable:
		return "función"
	if v is ScriptObject:
		return v.type_name()
	return "objeto"


static func is_number(v) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and typeof(v) != TYPE_BOOL


## Módulo como en Python (-7 % 3 == 2).
static func py_mod(a, b):
	if typeof(a) == TYPE_INT and typeof(b) == TYPE_INT:
		return a - b * int(floor(float(a) / float(b)))
	return a - b * floor(a / b)


## División entera como en Python (-7 // 2 == -4).
static func py_floordiv(a, b):
	if typeof(a) == TYPE_INT and typeof(b) == TYPE_INT:
		return int(floor(float(a) / float(b)))
	return floor(a / b)
