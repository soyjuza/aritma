@tool
## Base de las máquinas que llaman a una función del Códice (Molino, Raíces Gemelas).
class_name FunctionRoundsMachine
extends RoundsMachine

var function_name := ""


func setup(bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	super(bus, data, text, open_codex)
	function_name = String(data.get("function", ""))


## Los argumentos con que se llama la función en esa ronda.
func args_for(v) -> Array:
	return [v]


## Cómo se anota lo que devolvió.
func shown(returned) -> String:
	return ScriptContext.to_text(_whole(returned))


func after_run(result: ScriptSandbox.Result, sandbox: ScriptSandbox, v, record: Callable) -> String:
	var call := sandbox.call_function(result, function_name, args_for(v))
	if not call[0]:
		return String(call[1])
	record.call(shown(call[1]))
	return ""


## 15.0 se muestra como 15.
static func _whole(x):
	if typeof(x) == TYPE_FLOAT and is_equal_approx(x, round(x)):
		return int(round(x))
	return x
