## Una tabla del juego: nombre, columnas y filas. Las máquinas inventan las suyas en cada ronda.
class_name SqlTable
extends RefCounted

var name := ""
var columns: Array = []    # ["nombre", "peso"]
var rows: Array = []       # [["Roca", 12], ["Miel", 4]]


func _init(p_name := "", p_columns: Array = [], p_rows: Array = []) -> void:
	name = p_name
	columns = p_columns
	rows = p_rows


## {"name": "gatos", "columns": [...], "rows": [[...], ...]} (practices.json, pruebas).
static func from_data(data: Dictionary) -> SqlTable:
	return SqlTable.new(String(data.get("name", "")), data.get("columns", []), data.get("rows", []))


func to_data() -> Dictionary:
	return {"name": name, "columns": columns, "rows": rows}


## Posición de una columna (sin importar mayúsculas), o -1.
func column_index(column: String) -> int:
	var low := column.to_lower()
	for i in columns.size():
		if String(columns[i]).to_lower() == low:
			return i
	return -1


## Filas cuyo valor en column está en values.
func rows_with(column: String, values: Array) -> Array:
	var at := column_index(column)
	if at < 0:
		return []
	var shown := values.map(func(v): return SqlEngine.show(v))
	return range(rows.size()).filter(func(i): return SqlEngine.show(rows[i][at]) in shown)


## La tabla como texto alineado, para la consola y la ayuda del Códice.
func lines(max_rows := 12) -> Array:
	return SqlEngine.grid(columns, rows, max_rows)
