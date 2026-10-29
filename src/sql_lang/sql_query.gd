## Patrón Interpreter: una consulta ya leída. La arma SqlParser y la corre SqlEngine.
class_name SqlQuery
extends RefCounted

var star := false
var items: Array = []      # [{"expr": Expr, "name": "nombre"}]
var from: Dictionary = {}  # {"name": "carretas", "alias": "", "line": 1}
var joins: Array = []      # [{"name", "alias", "line", "on": Expr}]
var where: Expr = null
var order: Array = []      # [{"expr": Expr, "desc": false}]
var limit := -1


## Un pedazo de la consulta: un número, un texto, una columna o una cuenta.
class Expr extends RefCounted:
	var kind := ""        # num, text, col, bin, not, neg, agg
	var value = null
	var op := ""          # =, <, AND, +, COUNT...
	var a: Expr = null
	var b: Expr = null
	var table := ""       # carretas en carretas.peso
	var name := ""        # peso
	var text := ""        # cómo se escribió (para el nombre de la columna)
	var line := 0
	# Lo pone SqlEngine al revisar la consulta
	var source := -1
	var column := -1

	static func literal(p_kind: String, p_value, p_text: String, p_line: int) -> Expr:
		var e := Expr.new()
		e.kind = p_kind
		e.value = p_value
		e.text = p_text
		e.line = p_line
		return e

	static func column_ref(p_table: String, p_name: String, p_line: int) -> Expr:
		var e := Expr.new()
		e.kind = "col"
		e.table = p_table
		e.name = p_name
		e.text = (p_table + "." + p_name) if p_table != "" else p_name
		e.line = p_line
		return e

	static func binary(p_op: String, left: Expr, right: Expr) -> Expr:
		var e := Expr.new()
		e.kind = "bin"
		e.op = p_op
		e.a = left
		e.b = right
		e.text = "%s %s %s" % [left.text, p_op, right.text]
		e.line = left.line
		return e

	static func unary(p_kind: String, inner: Expr, p_line: int) -> Expr:
		var e := Expr.new()
		e.kind = p_kind
		e.a = inner
		e.text = ("NOT " if p_kind == "not" else "-") + inner.text
		e.line = p_line
		return e

	static func aggregate(p_op: String, inner: Expr, p_line: int) -> Expr:
		var e := Expr.new()
		e.kind = "agg"
		e.op = p_op
		e.a = inner    # null = COUNT(*)
		e.text = "%s(%s)" % [p_op, inner.text if inner else "*"]
		e.line = p_line
		return e

	## Una pregunta que se responde sí o no (para WHERE, ON, AND, OR y NOT).
	func is_condition() -> bool:
		return kind == "not" or (kind == "bin" and op in SqlParser.COMPARE + ["AND", "OR"])

	func has_aggregate() -> bool:
		if kind == "agg":
			return true
		return (a != null and a.has_aggregate()) or (b != null and b.has_aggregate())
