## Función del juego para el Códice (range, decir...). Revisa cuántos argumentos llegan.
class_name HostFunction
extends ScriptCallable

var min_args: int
var max_args: int
var _fn: Callable


func _init(p_name: String, fn: Callable, p_min := 0, p_max := 0) -> void:
	name = p_name
	_fn = fn
	min_args = p_min
	max_args = p_max


func invoke(ctx: ScriptContext, args: Array, line: int):
	if args.size() < min_args or args.size() > max_args:
		var expected := str(min_args) if min_args == max_args else "%d a %d" % [min_args, max_args]
		ctx.fail(ScriptMessages.text("recibe_argumento_y_le_diste_2") % [name, expected, args.size()], line)
		return null
	return _fn.call(ctx, args, line)
