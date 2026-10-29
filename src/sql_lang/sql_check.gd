## Compara lo que trajo la consulta del jugador con lo que trae la respuesta de la sala.
## Devuelve {} si es lo mismo; si no, la clave del aviso (texts.json) y sus datos.
class_name SqlCheck
extends RefCounted


static func compare(got: SqlEngine.Result, want: SqlEngine.Result, ordered: bool) -> Dictionary:
	var got_names: Array = got.columns.map(func(c): return String(c).to_lower())
	var want_names: Array = want.columns.map(func(c): return String(c).to_lower())
	var info := {"got_columns": ", ".join(got.columns), "want_columns": ", ".join(want.columns), "got": got.rows.size(), "want": want.rows.size()}
	# Las columnas pueden venir en otro orden; se acomodan como las pide la sala
	var pick: Array = []
	for name in want_names:
		var at := got_names.find(name)
		if at < 0 or got_names.size() != want_names.size() or at in pick:
			info.key = "sql_check_columns"
			return info
		pick.append(at)
	var got_rows: Array = got.rows.map(func(r): return " | ".join(pick.map(func(i): return SqlEngine.show(r[i]))))
	var want_rows: Array = want.rows.map(func(r): return " | ".join(r.map(func(v): return SqlEngine.show(v))))
	var extra := got_rows.duplicate()
	var missing: Array = []
	for row in want_rows:
		var at := extra.find(row)
		if at >= 0:
			extra.remove_at(at)
		else:
			missing.append(row)
	if not extra.is_empty():
		info.key = "sql_check_extra"
		info.row = extra[0]
		return info
	if not missing.is_empty():
		info.key = "sql_check_missing"
		info.row = missing[0]
		return info
	if ordered and got_rows != want_rows:
		info.key = "sql_check_order"
		info.got_order = ", ".join(got_rows)
		info.want_order = ", ".join(want_rows)
		return info
	return {}
