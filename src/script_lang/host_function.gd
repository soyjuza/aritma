## Función del juego disponible en el Códice (por ejemplo avanzar, range o decir).
## Envuelve un Callable de GDScript y revisa la cantidad de argumentos antes de llamarlo.
## El Callable recibe (ctx, args, line) y devuelve el resultado.
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
		ctx.fail("%s() recibe %s argumento(s) y le diste %d." % [name, expected, args.size()], line)
		return null
	return _fn.call(ctx, args, line)
