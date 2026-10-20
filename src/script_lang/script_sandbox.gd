## Patrón Facade: el juego solo llama run(código, objetos).
class_name ScriptSandbox
extends RefCounted

const MAX_RANGE := 100000


class Result:
	var ok := false
	var output: Array[String] = []
	var error := ""
	var line := 0
	var steps := 0
	var context: ScriptContext

	func error_text() -> String:
		return "Línea %d: %s" % [line, error] if line > 0 else error


## Ejecuta un programa. api: objetos del juego ("puerta", "guardian"...).
func run(source: String, api: Dictionary = {}, max_steps := 200000) -> Result:
	var result := Result.new()
	var ctx := ScriptContext.new()
	ctx.max_steps = max_steps
	result.context = ctx
	var lexer := Lexer.new()
	var tokens := lexer.tokenize(source)
	if lexer.error != "":
		result.error = lexer.error
		result.line = lexer.error_line
		return result
	var parser := Parser.new()
	var program := parser.parse(tokens)
	if program == null:
		result.error = parser.error
		result.line = parser.error_line
		return result
	_install_builtins(ctx)
	for key in api.keys():
		ctx.globals[key] = api[key]
	program.execute(ctx)
	result.output = ctx.output
	result.steps = ctx.steps
	if ctx.failed():
		result.error = ctx.error
		result.line = ctx.error_line
		return result
	if ctx.flow == "break" or ctx.flow == "continue":
		result.error = ScriptMessages.text("solo_dentro_for_while") % ctx.flow
		return result
	result.ok = true
	return result


## Llama a una función del programa. Devuelve [ok, valor o error].
func call_function(result: Result, function_name: String, args: Array) -> Array:
	var ctx := result.context
	if ctx == null or not ctx.globals.has(function_name) or not (ctx.globals[function_name] is ScriptCallable):
		return [false, ScriptMessages.text("no_encontre_funcion") % function_name]
	ctx.error = ""
	ctx.steps = 0
	var value = ctx.globals[function_name].invoke(ctx, args, 0)
	if ctx.failed():
		return [false, "Línea %d: %s" % [ctx.error_line, ctx.error]]
	return [true, value]


# ------------------------------------------------------------------ funciones incluidas

func _install_builtins(ctx: ScriptContext) -> void:
	var b := {
		"range": HostFunction.new("range", _range, 1, 3),
		"len": HostFunction.new("len", _len, 1, 1),
		"print": HostFunction.new("print", _print, 0, 8),
		"decir": HostFunction.new("decir", _print, 0, 8),
		"abs": HostFunction.new("abs", _abs, 1, 1),
		"min": HostFunction.new("min", _min_max.bind(true), 1, 8),
		"max": HostFunction.new("max", _min_max.bind(false), 1, 8),
		"int": HostFunction.new("int", _int, 1, 1),
		"str": HostFunction.new("str", func(_c, a, _l): return ScriptContext.to_text(a[0]), 1, 1),
		"bin": HostFunction.new("bin", _bin, 1, 1),
		"sum": HostFunction.new("sum", _sum, 1, 1),
		"round": HostFunction.new("round", func(_c, a, _l): return int(round(float(a[0]))), 1, 1),
		"sorted": HostFunction.new("sorted", _sorted, 1, 1),
	}
	for key in b.keys():
		ctx.globals[key] = b[key]


func _range(ctx: ScriptContext, args: Array, line: int):
	for a in args:
		if typeof(a) != TYPE_INT:
			ctx.fail(ScriptMessages.text("range_necesita_numeros_enteros"), line)
			return null
	var start := 0
	var stop: int = args[0]
	var step := 1
	if args.size() >= 2:
		start = args[0]
		stop = args[1]
	if args.size() == 3:
		step = args[2]
	if step == 0:
		ctx.fail(ScriptMessages.text("range_no_puede_avanzar"), line)
		return null
	var out: Array = []
	var i := start
	while (step > 0 and i < stop) or (step < 0 and i > stop):
		out.append(i)
		i += step
		if out.size() > MAX_RANGE:
			ctx.fail(ScriptMessages.text("range_demasiado_grande"), line)
			return null
	return out


func _len(ctx: ScriptContext, args: Array, line: int):
	var v = args[0]
	if typeof(v) == TYPE_ARRAY:
		return v.size()
	if typeof(v) == TYPE_STRING:
		return v.length()
	ctx.fail(ScriptMessages.text("len_necesita_lista_o_texto"), line)
	return null


func _print(ctx: ScriptContext, args: Array, _line: int):
	var parts: Array = []
	for a in args:
		parts.append(ScriptContext.to_text(a))
	ctx.print_line(" ".join(parts))
	return null


func _abs(ctx: ScriptContext, args: Array, line: int):
	if not ScriptContext.is_number(args[0]):
		ctx.fail(ScriptMessages.text("abs_necesita_numero"), line)
		return null
	return absi(args[0]) if typeof(args[0]) == TYPE_INT else absf(args[0])


func _min_max(ctx: ScriptContext, args: Array, line: int, is_min: bool):
	var items: Array = args[0] if args.size() == 1 and typeof(args[0]) == TYPE_ARRAY else args
	if items.is_empty():
		ctx.fail(ScriptMessages.text("min_max_lista_vacia"), line)
		return null
	var best = items[0]
	for item in items:
		if not ScriptContext.is_number(item):
			ctx.fail(ScriptMessages.text("min_max_necesitan_numeros"), line)
			return null
		if (is_min and item < best) or (not is_min and item > best):
			best = item
	return best


func _int(ctx: ScriptContext, args: Array, line: int):
	var v = args[0]
	if typeof(v) == TYPE_STRING:
		if v.strip_edges().is_valid_int():
			return int(v)
		ctx.fail(ScriptMessages.text("no_es_numero_entero") % v, line)
		return null
	if ScriptContext.is_number(v) or typeof(v) == TYPE_BOOL:
		return int(v)
	ctx.fail(ScriptMessages.text("int_no_entiende") % ScriptContext.type_name(v), line)
	return null


func _bin(ctx: ScriptContext, args: Array, line: int):
	if typeof(args[0]) != TYPE_INT:
		ctx.fail(ScriptMessages.text("bin_necesita_numero_entero"), line)
		return null
	var n: int = args[0]
	if n == 0:
		return "0b0"
	var digits := ""
	var m := absi(n)
	while m > 0:
		digits = str(m & 1) + digits
		m >>= 1
	return ("-0b" if n < 0 else "0b") + digits


func _sum(ctx: ScriptContext, args: Array, line: int):
	if typeof(args[0]) != TYPE_ARRAY:
		ctx.fail(ScriptMessages.text("sum_necesita_lista"), line)
		return null
	var total = 0
	for item in args[0]:
		if not ScriptContext.is_number(item):
			ctx.fail(ScriptMessages.text("sum_necesita_lista_numeros"), line)
			return null
		total += item
	return total


func _sorted(ctx: ScriptContext, args: Array, line: int):
	if typeof(args[0]) != TYPE_ARRAY:
		ctx.fail(ScriptMessages.text("sorted_necesita_lista"), line)
		return null
	var copy: Array = args[0].duplicate()
	copy.sort()
	return copy
