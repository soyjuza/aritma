## Patrón Interpreter: lee las piezas del SqlLexer y arma una SqlQuery.
## Orden: SELECT … FROM … [INNER] JOIN … ON … WHERE … ORDER BY … LIMIT …
class_name SqlParser
extends RefCounted

const COMPARE := ["=", "<>", "!=", "<", ">", "<=", ">="]
const AGGREGATES := ["COUNT", "SUM", "MIN", "MAX", "AVG"]
const KEYWORDS := ["SELECT", "FROM", "JOIN", "INNER", "ON", "WHERE", "ORDER", "BY", "ASC", "DESC", "LIMIT", "AND", "OR", "NOT", "AS"]
const READ_ONLY := ["INSERT", "UPDATE", "DELETE", "DROP", "CREATE", "ALTER", "TRUNCATE"]
const OTHER_JOINS := ["LEFT", "RIGHT", "FULL", "OUTER", "CROSS", "NATURAL"]
const NOT_HERE := ["GROUP", "HAVING", "LIKE", "IN", "BETWEEN", "IS", "NULL", "DISTINCT", "UNION", "CASE"]

var error := ""
var error_line := 0

var _tokens: Array = []
var _pos := 0


func parse(tokens: Array) -> SqlQuery:
	_tokens = tokens
	_pos = 0
	error = ""
	var first := _peek()
	if first.type == "end":
		return _fail("consulta_vacia", {}, first)
	if not _is(first, "SELECT"):
		if first.upper in READ_ONLY:
			return _fail("solo_leer", {"palabra": first.upper}, first)
		if _looks_like(first, "SELECT"):
			return _fail("quisiste_decir", {"escrito": first.text, "palabra": "SELECT"}, first)
		return _fail("empieza_select", {"escrito": first.text}, first)
	_next()
	var q := SqlQuery.new()
	if not _columns(q):
		return null
	if not _from(q):
		return null
	while _is(_peek(), "JOIN") or _is(_peek(), "INNER"):
		if not _join(q):
			return null
	if _is(_peek(), "WHERE"):
		var where_token := _next()
		if _clause_or_end(_peek()):
			return _fail("where_sin_condicion", {}, where_token)
		q.where = _expr()
		if q.where == null:
			return null
		if not q.where.is_condition():
			return _fail("no_es_pregunta", {"parte": "WHERE", "escrito": q.where.text}, where_token)
	if _is(_peek(), "ORDER"):
		if not _order(q):
			return null
	if _is(_peek(), "LIMIT"):
		var limit_token := _next()
		var n := _peek()
		if n.type != "number" or typeof(n.value) != TYPE_INT:
			return _fail("limit_numero", {}, limit_token)
		q.limit = int(_next().value)
	if _symbol(_peek(), ";"):
		_next()
	return q if _at_end() else null


# ------------------------------------------------------------------ partes de la consulta

func _columns(q: SqlQuery) -> bool:
	var t := _peek()
	if _is(t, "FROM") or t.type == "end" or _symbol(t, ";"):
		_fail("faltan_columnas", {}, t)
		return false
	if _symbol(t, "*"):
		_next()
		q.star = true
		if _symbol(_peek(), ","):
			_fail("estrella_sola", {}, _peek())
			return false
		return true
	while true:
		var e := _expr()
		if e == null:
			return false
		var item := {"expr": e, "name": e.name if e.kind == "col" else e.text}
		if _is(_peek(), "AS"):
			_next()
			var alias := _peek()
			if alias.type != "word" or alias.upper in KEYWORDS:
				_fail("as_sin_nombre", {}, alias)
				return false
			item.name = String(_next().text)
		q.items.append(item)
		if not _symbol(_peek(), ","):
			return true
		_next()
		if _is(_peek(), "FROM"):
			_fail("coma_de_mas", {}, _peek())
			return false
	return true


func _from(q: SqlQuery) -> bool:
	var t := _peek()
	if not _is(t, "FROM"):
		if t.type == "end" or _symbol(t, ";"):
			_fail("falta_from", {}, t)
		elif _looks_like(t, "FROM"):
			_fail("quisiste_decir", {"escrito": t.text, "palabra": "FROM"}, t)
		elif t.type == "word" and not t.upper in KEYWORDS:
			_fail("falta_coma", {"antes": _tokens[_pos - 1].text, "escrito": t.text}, t)
		else:
			_fail("falta_from", {}, t)
		return false
	_next()
	var table := _table_ref("FROM")
	if table.is_empty():
		return false
	q.from = table
	return true


func _join(q: SqlQuery) -> bool:
	var start := _next()
	if _is(start, "INNER"):
		if not _is(_peek(), "JOIN"):
			_fail("inner_sin_join", {}, _peek())
			return false
		_next()
	var table := _table_ref("JOIN")
	if table.is_empty():
		return false
	if not _is(_peek(), "ON"):
		if _looks_like(_peek(), "ON") and _peek().type == "word":
			_fail("quisiste_decir", {"escrito": _peek().text, "palabra": "ON"}, _peek())
		else:
			_fail("join_sin_on", {"tabla": table.name}, _peek())
		return false
	var on_token := _next()
	if _clause_or_end(_peek()):
		_fail("on_sin_condicion", {}, on_token)
		return false
	var on := _expr()
	if on == null:
		return false
	if not on.is_condition():
		_fail("no_es_pregunta", {"parte": "ON", "escrito": on.text}, on_token)
		return false
	table.on = on
	q.joins.append(table)
	return true


func _order(q: SqlQuery) -> bool:
	var order_token := _next()
	if not _is(_peek(), "BY"):
		_fail("order_sin_by", {}, order_token)
		return false
	_next()
	while true:
		if _clause_or_end(_peek()):
			_fail("order_sin_columna", {}, order_token)
			return false
		var e := _expr()
		if e == null:
			return false
		var desc := false
		if _is(_peek(), "DESC"):
			_next()
			desc = true
		elif _is(_peek(), "ASC"):
			_next()
		elif _looks_like(_peek(), "DESC") and _peek().type == "word":
			_fail("quisiste_decir", {"escrito": _peek().text, "palabra": "DESC"}, _peek())
			return false
		q.order.append({"expr": e, "desc": desc})
		if not _symbol(_peek(), ","):
			return true
		_next()
	return true


## "carretas", "carretas c" o "carretas AS c".
func _table_ref(after: String) -> Dictionary:
	var t := _peek()
	if t.type != "word" or t.upper in KEYWORDS:
		_fail("falta_tabla", {"parte": after}, t)
		return {}
	_next()
	var ref := {"name": String(t.text), "alias": "", "line": int(t.line)}
	var next := _peek()
	if _is(next, "AS"):
		_next()
		next = _peek()
		if next.type != "word" or next.upper in KEYWORDS:
			_fail("as_sin_nombre", {}, next)
			return {}
	if next.type == "word" and not next.upper in KEYWORDS + OTHER_JOINS + NOT_HERE:
		_next()
		ref.alias = String(next.text)
		# «FROM carretas peso > 10»: se comió el WHERE
		if _peek().type == "symbol" and _peek().text in COMPARE + ["=="]:
			_fail("falta_where", {"escrito": next.text}, next)
			return {}
	return ref


## Lo que sobra al final.
func _at_end() -> bool:
	var t := _peek()
	if t.type == "end":
		return true
	if t.type == "word":
		if t.upper == "SELECT":
			_fail("una_consulta", {}, t)
		elif t.upper in ["FROM", "WHERE", "ORDER", "LIMIT", "JOIN", "INNER", "ON"]:
			_fail("orden_partes", {"palabra": t.upper}, t)
		elif t.upper in OTHER_JOINS:
			_fail("solo_inner", {"palabra": t.upper}, t)
		elif t.upper in NOT_HERE:
			_fail("no_se_usa", {"palabra": t.upper}, t)
		elif t.upper in ["AND", "OR"]:
			_fail("and_sin_where", {"palabra": t.upper}, t)
		elif _looks_like(t, "WHERE") or _looks_like(t, "ORDER") or _looks_like(t, "LIMIT"):
			_fail("quisiste_decir", {"escrito": t.text, "palabra": _closest_keyword(t)}, t)
		else:
			_fail("no_esperaba", {"escrito": t.text}, t)
	elif _symbol(t, ";"):
		_fail("una_consulta", {}, t)
	else:
		_fail("no_esperaba", {"escrito": t.text}, t)
	return false


# ------------------------------------------------------------------ expresiones

func _expr() -> SqlQuery.Expr:
	return _or()


func _or() -> SqlQuery.Expr:
	var left := _and()
	while left != null and _is(_peek(), "OR"):
		var op := _next()
		if _clause_or_end(_peek()):
			return _fail("falta_condicion_despues", {"palabra": "OR"}, op)
		var right := _and()
		if right == null:
			return null
		if not left.is_condition() or not right.is_condition():
			return _fail("no_es_pregunta", {"parte": "OR", "escrito": (right if left.is_condition() else left).text}, op)
		left = SqlQuery.Expr.binary("OR", left, right)
	return left


func _and() -> SqlQuery.Expr:
	var left := _not()
	while left != null and _is(_peek(), "AND"):
		var op := _next()
		if _clause_or_end(_peek()):
			return _fail("falta_condicion_despues", {"palabra": "AND"}, op)
		var right := _not()
		if right == null:
			return null
		if not left.is_condition() or not right.is_condition():
			return _fail("no_es_pregunta", {"parte": "AND", "escrito": (right if left.is_condition() else left).text}, op)
		left = SqlQuery.Expr.binary("AND", left, right)
	return left


func _not() -> SqlQuery.Expr:
	if _is(_peek(), "NOT"):
		var t := _next()
		var inner := _not()
		if inner == null:
			return null
		if not inner.is_condition():
			return _fail("no_es_pregunta", {"parte": "NOT", "escrito": inner.text}, t)
		return SqlQuery.Expr.unary("not", inner, int(t.line))
	return _compare()


func _compare() -> SqlQuery.Expr:
	var left := _sum()
	if left == null:
		return null
	var t := _peek()
	if _symbol(t, "=="):
		return _fail("doble_igual", {}, t)
	if _symbol(t, "=>") or _symbol(t, "=<"):
		return _fail("signo_al_reves", {"escrito": t.text, "bien": t.text[1] + "="}, t)
	if t.type == "symbol" and t.text in COMPARE:
		_next()
		if _clause_or_end(_peek()):
			return _fail("falta_valor_despues", {"signo": t.text}, t)
		var right := _sum()
		if right == null:
			return null
		var op: String = "<>" if t.text == "!=" else t.text
		return SqlQuery.Expr.binary(op, left, right)
	return left


func _sum() -> SqlQuery.Expr:
	var left := _product()
	while left != null and _peek().type == "symbol" and _peek().text in ["+", "-"]:
		var op := _next()
		var right := _product()
		if right == null:
			return null
		left = SqlQuery.Expr.binary(op.text, left, right)
	return left


func _product() -> SqlQuery.Expr:
	var left := _unary()
	while left != null and _peek().type == "symbol" and _peek().text in ["*", "/", "%"]:
		var op := _next()
		var right := _unary()
		if right == null:
			return null
		left = SqlQuery.Expr.binary(op.text, left, right)
	return left


func _unary() -> SqlQuery.Expr:
	if _symbol(_peek(), "-"):
		var t := _next()
		var inner := _unary()
		return SqlQuery.Expr.unary("neg", inner, int(t.line)) if inner else null
	return _primary()


func _primary() -> SqlQuery.Expr:
	var t := _peek()
	match t.type:
		"number":
			_next()
			return SqlQuery.Expr.literal("num", t.value, t.text, int(t.line))
		"text":
			_next()
			return SqlQuery.Expr.literal("text", t.value, t.text, int(t.line))
		"end":
			return _fail("consulta_incompleta", {}, t)
	if _symbol(t, "("):
		_next()
		var inner := _expr()
		if inner == null:
			return null
		if not _symbol(_peek(), ")"):
			return _fail("falta_parentesis", {}, _peek())
		_next()
		return inner
	if t.type == "symbol":
		return _fail("esperaba_valor", {"escrito": t.text}, t)
	if t.upper in AGGREGATES and _symbol(_peek(1), "("):
		_next()
		_next()
		var inner: SqlQuery.Expr = null
		if _symbol(_peek(), "*"):
			if t.upper != "COUNT":
				return _fail("estrella_solo_count", {"funcion": t.upper}, t)
			_next()
		else:
			inner = _expr()
			if inner == null:
				return null
		if not _symbol(_peek(), ")"):
			return _fail("falta_parentesis", {}, _peek())
		_next()
		return SqlQuery.Expr.aggregate(t.upper, inner, int(t.line))
	if t.upper in KEYWORDS:
		return _fail("esperaba_valor", {"escrito": t.text}, t)
	if t.upper in READ_ONLY + OTHER_JOINS + NOT_HERE:
		return _fail("no_se_usa", {"palabra": t.upper}, t)
	_next()
	if _symbol(_peek(), "."):
		_next()
		var column := _peek()
		if column.type != "word":
			return _fail("punto_sin_columna", {"tabla": t.text}, column)
		_next()
		return SqlQuery.Expr.column_ref(String(t.text), String(column.text), int(t.line))
	return SqlQuery.Expr.column_ref("", String(t.text), int(t.line))


# ------------------------------------------------------------------ ayudas

func _peek(ahead := 0) -> Dictionary:
	return _tokens[mini(_pos + ahead, _tokens.size() - 1)]


func _next() -> Dictionary:
	var t := _peek()
	_pos = mini(_pos + 1, _tokens.size() - 1)
	return t


static func _is(t: Dictionary, keyword: String) -> bool:
	return t.type == "word" and t.upper == keyword


static func _symbol(t: Dictionary, s: String) -> bool:
	return t.type == "symbol" and t.text == s


## Lo que viene es otra parte de la consulta, o se acabó.
static func _clause_or_end(t: Dictionary) -> bool:
	return t.type == "end" or _symbol(t, ";") or (t.type == "word" and t.upper in ["FROM", "WHERE", "ORDER", "LIMIT", "JOIN", "INNER", "ON", "AND", "OR"])


## Una palabra mal escrita que se parece a keyword («SELEC», «FORM»).
static func _looks_like(t: Dictionary, keyword: String) -> bool:
	return t.type == "word" and t.upper != keyword and distance(t.upper, keyword) <= (1 if keyword.length() <= 2 else 2)


static func _closest_keyword(t: Dictionary) -> String:
	var best := ""
	var best_d := 99
	for k in KEYWORDS:
		var d := distance(t.upper, k)
		if d < best_d:
			best = k
			best_d = d
	return best


## Cuántas letras hay que cambiar para pasar de a a b (Levenshtein).
static func distance(a: String, b: String) -> int:
	var prev: Array = range(b.length() + 1)
	for i in a.length():
		var cur: Array = [i + 1]
		for j in b.length():
			var cost := 0 if a[i] == b[j] else 1
			cur.append(mini(mini(cur[j] + 1, prev[j + 1] + 1), prev[j] + cost))
		prev = cur
	return prev[b.length()]


func _fail(key: String, params: Dictionary, t: Dictionary) -> Variant:
	if error == "":
		error = SqlMessages.text(key, params)
		error_line = int(t.get("line", 0))
	return null
