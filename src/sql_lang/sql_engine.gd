## Patrón Facade: el juego solo llama run(consulta, tablas) y recibe las filas o el error.
## Por dentro: SqlLexer → SqlParser → revisar nombres → FROM/JOIN → WHERE → ORDER BY → SELECT → LIMIT.
class_name SqlEngine
extends RefCounted

const MAX_ROWS := 5000    # un JOIN sin ON bien puesto puede crecer mucho


class Result:
	var ok := false
	var columns: Array = []
	var rows: Array = []
	var error := ""
	var line := 0
	var multiline := false

	func error_text() -> String:
		return SqlMessages.text("en_linea", {"n": line, "error": error}) if line > 0 and multiline else error


var _sources: Array = []    # [{"name", "alias", "table": SqlTable}]
var _error := ""
var _error_line := 0


## Corre una consulta sobre tables (Array de SqlTable).
func run(source: String, tables: Array) -> Result:
	var result := Result.new()
	result.multiline = count_lines(source) > 1
	var lexer := SqlLexer.new()
	var tokens := lexer.tokenize(source)
	if lexer.error != "":
		result.error = lexer.error
		result.line = lexer.error_line
		return result
	var parser := SqlParser.new()
	var query := parser.parse(tokens)
	if query == null:
		result.error = parser.error
		result.line = parser.error_line
		return result
	_error = ""
	_error_line = 0
	_sources = []
	_execute(query, tables, result)
	if _error != "":
		result.error = _error
		result.line = _error_line
		result.columns = []
		result.rows = []
		return result
	result.ok = true
	return result


func _execute(q: SqlQuery, tables: Array, result: Result) -> void:
	# FROM y JOIN: cada combinación es una lista con una fila de cada tabla
	if not _add_source(q.from, tables):
		return
	var combos: Array = (_sources[0].table as SqlTable).rows.map(func(r): return [r])
	for join: Dictionary in q.joins:
		if not _add_source(join, tables) or not _bind(join.on):
			return
		var joined: Array = []
		var right: SqlTable = _sources[-1].table
		for combo: Array in combos:
			for row in right.rows:
				var both: Array = combo + [row]
				var keep = _eval(join.on, both)
				if _error != "":
					return
				if keep == true:
					joined.append(both)
					if joined.size() > MAX_ROWS:
						_fail("demasiadas_filas", {}, join.line)
						return
		combos = joined
	# WHERE
	if q.where:
		if q.where.has_aggregate():
			_fail("cuenta_en_where", {}, q.where.line)
			return
		if not _bind(q.where):
			return
		var kept: Array = []
		for combo: Array in combos:
			var keep = _eval(q.where, combo)
			if _error != "":
				return
			if keep == true:
				kept.append(combo)
		combos = kept
	# Columnas pedidas
	var items: Array = []
	if q.star:
		for s in _sources.size():
			var table: SqlTable = _sources[s].table
			for c in table.columns.size():
				var e := SqlQuery.Expr.column_ref("", String(table.columns[c]), 0)
				e.source = s
				e.column = c
				items.append({"expr": e, "name": String(table.columns[c])})
	else:
		for item: Dictionary in q.items:
			if not _bind(item.expr):
				return
			items.append(item)
	result.columns = items.map(func(i): return i.name)
	# Con COUNT, SUM... todas las filas se juntan en una
	if items.any(func(i): return (i.expr as SqlQuery.Expr).has_aggregate()):
		for item: Dictionary in items:
			var e: SqlQuery.Expr = item.expr
			if not e.has_aggregate():
				_fail("mezcla_cuenta", {"columna": e.text}, e.line)
				return
		var row: Array = []
		for item: Dictionary in items:
			row.append(_eval_aggregate(item.expr, combos))
			if _error != "":
				return
		result.rows = [row]
		return
	# ORDER BY
	if not q.order.is_empty():
		var keys: Array = []
		for o: Dictionary in q.order:
			var e: SqlQuery.Expr = _order_expr(o.expr, items)
			if e.has_aggregate():
				_fail("cuenta_en_order", {}, e.line)
				return
			if not _bind(e):
				return
			keys.append({"expr": e, "desc": o.desc})
		var decorated: Array = []
		for i in combos.size():
			var values: Array = []
			for k: Dictionary in keys:
				values.append(_eval(k.expr, combos[i]))
				if _error != "":
					return
			decorated.append([values, i, combos[i]])
		decorated.sort_custom(func(x, y): return _before(x, y, keys))
		combos = decorated.map(func(d): return d[2])
	# SELECT
	for combo: Array in combos:
		var row: Array = []
		for item: Dictionary in items:
			row.append(_eval(item.expr, combo))
			if _error != "":
				return
		result.rows.append(row)
	if q.limit >= 0:
		result.rows = result.rows.slice(0, q.limit)


# ------------------------------------------------------------------ tablas y columnas

func _add_source(ref: Dictionary, tables: Array) -> bool:
	var found: SqlTable = null
	for t: SqlTable in tables:
		if t.name.to_lower() == String(ref.name).to_lower():
			found = t
	var names := tables.map(func(t): return t.name)
	if found == null:
		var near := _closest(String(ref.name), names)
		if near != "":
			return _no("no_tabla_parecida", {"tabla": ref.name, "parecida": near}, ref.line)
		return _no("no_tabla", {"tabla": ref.name, "tablas": ", ".join(names)}, ref.line)
	var label := (String(ref.alias) if ref.alias != "" else String(ref.name)).to_lower()
	for s: Dictionary in _sources:
		if s.label == label:
			return _no("tabla_repetida", {"tabla": ref.name}, ref.line)
	_sources.append({"name": found.name, "alias": String(ref.alias), "label": label, "table": found})
	return true


func _find_source(name: String) -> int:
	var low := name.to_lower()
	for i in _sources.size():
		if _sources[i].label == low:
			return i
	for i in _sources.size():
		if String(_sources[i].name).to_lower() == low:
			return i
	return -1


## Pone en cada columna de e de qué tabla y en qué posición está.
func _bind(e: SqlQuery.Expr) -> bool:
	if e == null:
		return true
	if e.kind == "col":
		return _bind_column(e)
	return _bind(e.a) and _bind(e.b)


func _bind_column(e: SqlQuery.Expr) -> bool:
	if e.table != "":
		var s := _find_source(e.table)
		if s < 0:
			return _no("tabla_no_esta", {"tabla": e.table, "columna": e.name, "tablas": ", ".join(_sources.map(func(x): return x.name))}, e.line)
		var table: SqlTable = _sources[s].table
		var c := table.column_index(e.name)
		if c < 0:
			return _missing_column(e, [table])
		e.source = s
		e.column = c
		return true
	var found: Array = []
	for s in _sources.size():
		var c: int = (_sources[s].table as SqlTable).column_index(e.name)
		if c >= 0:
			found.append([s, c])
	if found.size() > 1:
		return _no("columna_ambigua", {"columna": e.name, "ejemplo": "%s.%s" % [_sources[found[0][0]].name, e.name]}, e.line)
	if found.is_empty():
		return _missing_column(e, _sources.map(func(x): return x.table))
	e.source = found[0][0]
	e.column = found[0][1]
	return true


func _missing_column(e: SqlQuery.Expr, tables: Array) -> bool:
	var all: Array = []
	for t: SqlTable in tables:
		all.append_array(t.columns)
	var near := _closest(e.name, all)
	if near != "":
		return _no("no_columna_parecida", {"columna": e.name, "parecida": near}, e.line)
	var key := "no_columna" if tables.size() == 1 else "no_columna_en_tablas"
	var listing := ", ".join(tables.map(func(t): return "%s(%s)" % [t.name, ", ".join(t.columns)]))
	return _no(key, {"tabla": tables[0].name, "columna": e.name, "columnas": ", ".join(tables[0].columns), "tablas": listing}, e.line)


## ORDER BY puede usar el nombre que se le dio a una columna con AS.
func _order_expr(e: SqlQuery.Expr, items: Array) -> SqlQuery.Expr:
	if e.kind == "col" and e.table != "":
		return e
	if e.kind == "col":
		for s: Dictionary in _sources:
			if (s.table as SqlTable).column_index(e.name) >= 0:
				return e
		for item: Dictionary in items:
			if String(item.name).to_lower() == e.name.to_lower():
				return item.expr
	return e


# ------------------------------------------------------------------ valores

func _eval(e: SqlQuery.Expr, combo: Array):
	match e.kind:
		"num", "text":
			return e.value
		"col":
			return combo[e.source][e.column]
		"neg":
			var v = _eval(e.a, combo)
			if _error != "":
				return null
			if not is_number(v):
				return _fail("menos_texto", {"escrito": e.a.text}, e.line)
			return -v
		"not":
			var v = _eval(e.a, combo)
			return null if _error != "" else not v
		"agg":
			return _fail("cuenta_suelta", {"escrito": e.text}, e.line)
	# Binarias
	if e.op == "AND" or e.op == "OR":
		var left = _eval(e.a, combo)
		if _error != "":
			return null
		if e.op == "AND" and left == false:
			return false
		if e.op == "OR" and left == true:
			return true
		return _eval(e.b, combo)
	var l = _eval(e.a, combo)
	if _error != "":
		return null
	var r = _eval(e.b, combo)
	if _error != "":
		return null
	if e.op in SqlParser.COMPARE:
		return _compare(e, l, r)
	if not is_number(l) or not is_number(r):
		return _fail("cuenta_con_texto", {"escrito": e.text}, e.line)
	match e.op:
		"+":
			return l + r
		"-":
			return l - r
		"*":
			return l * r
		"/":
			if r == 0:
				return _fail("division_cero", {}, e.line)
			if typeof(l) == TYPE_INT and typeof(r) == TYPE_INT and l % r == 0:
				return l / r
			return float(l) / float(r)
		"%":
			if typeof(l) != TYPE_INT or typeof(r) != TYPE_INT or r == 0:
				return _fail("resto_enteros", {}, e.line)
			return posmod(l, r)
	return null


## Compara dos valores. Los textos, sin importar mayúsculas.
func _compare(e: SqlQuery.Expr, l, r):
	if is_number(l) != is_number(r):
		var text = r if is_number(l) else l
		var number = l if is_number(l) else r
		if String(text).strip_edges().is_valid_float():
			return _fail("numero_con_comillas", {"texto": text}, e.line)
		return _fail("compara_texto_numero", {"texto": text, "numero": show(number), "escrito": e.text}, e.line)
	var a = l if is_number(l) else String(l).to_lower()
	var b = r if is_number(r) else String(r).to_lower()
	match e.op:
		"=":
			return a == b
		"<>":
			return a != b
		"<":
			return a < b
		">":
			return a > b
		"<=":
			return a <= b
		">=":
			return a >= b
	return false


func _eval_aggregate(e: SqlQuery.Expr, combos: Array):
	if e.kind == "agg":
		if e.a == null:
			return combos.size()
		if e.a.has_aggregate():
			return _fail("cuenta_dentro_cuenta", {}, e.line)
		if not _bind(e.a):
			return null
		var values: Array = []
		for combo: Array in combos:
			values.append(_eval(e.a, combo))
			if _error != "":
				return null
		match e.op:
			"COUNT":
				return values.size()
			"SUM", "AVG":
				var total = 0
				for v in values:
					if not is_number(v):
						return _fail("suma_texto", {"funcion": e.op, "escrito": e.a.text}, e.line)
					total += v
				if e.op == "SUM":
					return total
				return null if values.is_empty() else float(total) / values.size()
			"MIN":
				return values.min() if not values.is_empty() else null
			"MAX":
				return values.max() if not values.is_empty() else null
		return null
	# Cuentas con COUNT adentro: COUNT(*) + 1
	if e.kind == "bin" and not e.op in ["AND", "OR"] and not e.op in SqlParser.COMPARE:
		var l = _eval_aggregate(e.a, combos)
		var r = _eval_aggregate(e.b, combos)
		if _error != "" or not is_number(l) or not is_number(r):
			return null
		match e.op:
			"+":
				return l + r
			"-":
				return l - r
			"*":
				return l * r
			"/":
				return float(l) / float(r) if r != 0 else _fail("division_cero", {}, e.line)
	if e.kind in ["num", "text"]:
		return e.value
	return _fail("mezcla_cuenta", {"columna": e.text}, e.line)


## Orden estable: si empatan, queda como estaba.
static func _before(x: Array, y: Array, keys: Array) -> bool:
	for i in keys.size():
		var a = x[0][i]
		var b = y[0][i]
		if typeof(a) == TYPE_STRING:
			a = String(a).to_lower()
		if typeof(b) == TYPE_STRING:
			b = String(b).to_lower()
		if is_number(a) != is_number(b):
			a = str(a)
			b = str(b)
		if a == b:
			continue
		return (a > b) if keys[i].desc else (a < b)
	return x[1] < y[1]


## Como _fail, para las funciones que responden sí o no.
func _no(key: String, params: Dictionary, line: int) -> bool:
	_fail(key, params, line)
	return false


func _fail(key: String, params: Dictionary, line: int) -> Variant:
	if _error == "":
		_error = SqlMessages.text(key, params)
		_error_line = line
	return null


# ------------------------------------------------------------------ ayudas

static func is_number(v) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT


## Cómo se ve un valor: 15.0 como 15.
static func show(v) -> String:
	if v == null:
		return "NULL"
	if typeof(v) == TYPE_FLOAT:
		if is_equal_approx(v, round(v)):
			return str(int(round(v)))
		return String.num(v, 2)
	return str(v)


## El nombre de names que más se parece a word (o "" si ninguno).
static func _closest(word: String, names: Array) -> String:
	var best := ""
	var best_d := 3
	for n in names:
		var d := SqlParser.distance(word.to_lower(), String(n).to_lower())
		if d < best_d and d <= maxi(1, String(n).length() / 3):
			best = String(n)
			best_d = d
	return best


## Líneas con algo (sin vacías ni comentarios).
static func count_lines(source: String) -> int:
	var n := 0
	for line in source.split("\n"):
		var t := line.strip_edges()
		if t != "" and not t.begins_with("--"):
			n += 1
	return n


## Una tabla como texto alineado.
static func grid(columns: Array, rows: Array, max_rows := 12) -> Array:
	var widths: Array = columns.map(func(c): return String(c).length())
	var cells: Array = rows.slice(0, max_rows).map(func(r): return r.map(func(v): return show(v)))
	for r: Array in cells:
		for i in mini(r.size(), widths.size()):
			widths[i] = maxi(widths[i], String(r[i]).length())
	var out: Array = [_grid_line(columns, widths)]
	out.append("-+-".join(widths.map(func(w): return "-".repeat(w))))
	for r: Array in cells:
		out.append(_grid_line(r, widths))
	if rows.size() > max_rows:
		out.append("...")
	return out


static func _grid_line(cells: Array, widths: Array) -> String:
	var parts: Array = []
	for i in cells.size():
		parts.append(String(cells[i]).rpad(widths[i]) if i < widths.size() else String(cells[i]))
	return " | ".join(parts).strip_edges(false, true)


## Lo que la consola muestra de un resultado.
static func result_lines(result: Result) -> Array:
	var out := grid(result.columns, result.rows)
	var n := result.rows.size()
	out.append(SqlMessages.text("filas_ninguna" if n == 0 else ("filas_una" if n == 1 else "filas_varias"), {"n": n}))
	return out
