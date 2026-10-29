## Reglas de la Criba, sin nada visible: al cáliz van las esferas que trajo la consulta
## y al crisol las demás. Cada paso queda como un FilterCommand.
class_name SphereSorter
extends RefCounted

var commands: Array = []
var fault_value := -1    # la primera esfera que cayó mal


## Una ronda. rows: las esferas; chosen: los números que trajo la consulta; wanted: los que
## debía traer; columns_ok: false si trajo otras columnas. Devuelve false si la Criba se traba.
func add_round(index: int, rows: Array, chosen: Array, wanted: Array, columns_ok: bool) -> bool:
	commands.append(FilterCommand.RoundStart.new(index, rows))
	for r in rows:
		var n := SqlEngine.show(r[0])
		var to_chalice := n in chosen
		commands.append(FilterCommand.Release.new(int(r[0])))
		var right := to_chalice == (n in wanted)
		commands.append(FilterCommand.Send.new(int(r[0]), to_chalice, right))
		if not right:
			fault_value = int(r[0])
			return false
	if not columns_ok:
		commands.append(FilterCommand.Jam.new())
		return false
	commands.append(FilterCommand.RoundDone.new(index))
	return true
