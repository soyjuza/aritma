## Pruebas del SQL del Códice: consultas que deben funcionar y errores que deben explicarse bien.
class_name SqlLangTests
extends RefCounted

var _engine := SqlEngine.new()
var _tables: Array = []


func _init() -> void:
	_tables = [
		SqlTable.new("carretas", ["nombre", "peso", "color"], [["Roca", 12, "gris"], ["Miel", 4, "dorada"], ["Sal", 10, "gris"], ["Leña", 15, "roja"]]),
		SqlTable.new("ninos", ["nombre", "mascota_id"], [["Ana", 1], ["Beto", 2], ["Coco", 0], ["Dani", 1]]),
		SqlTable.new("mascotas", ["id", "animal"], [[1, "perro"], [2, "gato"], [3, "loro"]]),
	]


func run_all(check: Callable) -> void:
	_queries(check)
	_errors(check)
	_compare(check)


## Lo que trae la consulta: "Roca|12; Miel|4"
func _rows(query: String) -> String:
	var r := _engine.run(query, _tables)
	if not r.ok:
		return "ERROR: " + r.error
	return "; ".join(r.rows.map(func(row): return "|".join(row.map(func(v): return SqlEngine.show(v)))))


func _error(query: String) -> String:
	var r := _engine.run(query, _tables)
	return "" if r.ok else r.error_text()


func _queries(check: Callable) -> void:
	check.call(_rows("SELECT nombre FROM carretas") == "Roca; Miel; Sal; Leña", "SQL: SELECT de una columna")
	check.call(_rows("select * from carretas;") == "Roca|12|gris; Miel|4|dorada; Sal|10|gris; Leña|15|roja", "SQL: SELECT * en minúsculas y con punto y coma")
	var r := _engine.run("SELECT peso, nombre FROM carretas", _tables)
	check.call(r.ok and r.columns == ["peso", "nombre"], "SQL: las columnas salen con su nombre y en el orden pedido")
	check.call(_rows("SELECT nombre FROM carretas WHERE peso > 10") == "Roca; Leña", "SQL: WHERE con >")
	check.call(_rows("SELECT nombre FROM carretas WHERE peso >= 10") == "Roca; Sal; Leña", "SQL: WHERE con >=")
	check.call(_rows("SELECT nombre FROM carretas WHERE color = 'GRIS'") == "Roca; Sal", "SQL: los textos se comparan sin importar mayúsculas")
	check.call(_rows("SELECT nombre FROM carretas WHERE color <> 'gris'") == "Miel; Leña", "SQL: <> es distinto")
	check.call(_rows("SELECT nombre FROM carretas WHERE peso > 5 AND color = 'gris'") == "Roca; Sal", "SQL: AND pide las dos")
	check.call(_rows("SELECT nombre FROM carretas WHERE peso < 5 OR color = 'roja'") == "Miel; Leña", "SQL: OR se conforma con una")
	check.call(_rows("SELECT nombre FROM carretas WHERE NOT (peso > 10 OR color = 'dorada')") == "Sal", "SQL: NOT y paréntesis")
	check.call(_rows("SELECT nombre FROM carretas ORDER BY peso") == "Miel; Sal; Roca; Leña", "SQL: ORDER BY de menor a mayor")
	check.call(_rows("SELECT nombre FROM carretas ORDER BY peso DESC LIMIT 2") == "Leña; Roca", "SQL: ORDER BY DESC y LIMIT")
	check.call(_rows("SELECT nombre FROM carretas ORDER BY color, nombre") == "Miel; Roca; Sal; Leña", "SQL: ORDER BY con dos columnas (estable)")
	check.call(_rows("SELECT ninos.nombre, mascotas.animal FROM ninos JOIN mascotas ON ninos.mascota_id = mascotas.id") == "Ana|perro; Beto|gato; Dani|perro", "SQL: JOIN empareja y deja fuera a quien no tiene pareja")
	check.call(_rows("SELECT n.nombre FROM ninos n INNER JOIN mascotas AS m ON n.mascota_id = m.id WHERE m.animal = 'perro'") == "Ana; Dani", "SQL: INNER JOIN con alias y WHERE")
	check.call(_rows("SELECT nombre, animal FROM ninos INNER JOIN mascotas ON mascota_id = id ORDER BY nombre DESC") == "Dani|perro; Beto|gato; Ana|perro", "SQL: columnas sin tabla cuando no hay dudas")
	check.call(_rows("SELECT COUNT(*) FROM carretas WHERE peso > 5") == "3", "SQL: COUNT(*)")
	check.call(_rows("SELECT SUM(peso), MAX(peso) FROM carretas") == "41|15", "SQL: SUM y MAX")
	check.call(_rows("SELECT nombre FROM carretas WHERE peso > 100") == "", "SQL: sin filas no es un error")
	check.call(_rows("-- comentario\nSELECT nombre\n  FROM carretas  -- otro\n WHERE peso = 4") == "Miel", "SQL: comentarios con -- y varias líneas")
	check.call(_rows("SELECT nombre FROM carretas WHERE color = ‘gris’") == "Roca; Sal", "SQL: las comillas curvas del celular también sirven")


func _errors(check: Callable) -> void:
	var cases := [
		["", "Empieza con SELECT", "vacía"],
		["SELEC nombre FROM carretas", "¿Quisiste decir SELECT?", "SELECT mal escrito"],
		["DELETE FROM carretas", "solo LEEN", "DELETE no se usa"],
		["SELECT nombre carretas", "falta FROM", "falta FROM"],
		["SELECT nombre peso FROM carretas", "¿Falta una coma", "falta la coma"],
		["SELECT nombre FORM carretas", "¿Quisiste decir FROM?", "FROM mal escrito"],
		["SELECT nombre FROM carreta", "¿Quisiste decir «carretas»?", "tabla mal escrita"],
		["SELECT nombre FROM gatos", "Las tablas de esta sala son", "tabla que no existe"],
		["SELECT nombr FROM carretas", "¿Quisiste decir «nombre»?", "columna mal escrita"],
		["SELECT nombre FROM carretas WHERE color = gris", "va entre comillas: 'gris'", "texto sin comillas"],
		["SELECT nombre FROM carretas WHERE color = \"gris\"", "comillas simples", "comillas dobles"],
		["SELECT nombre FROM carretas WHERE color = 'gris", "Falta cerrar el texto", "texto sin cerrar"],
		["SELECT nombre FROM carretas WHERE peso == 4", "un solo =", "=="],
		["SELECT nombre FROM carretas WHERE peso => 4", "Se escribe >=", "=> al revés"],
		["SELECT nombre FROM carretas WHERE", "Después de WHERE va una condición", "WHERE vacío"],
		["SELECT nombre FROM carretas WHERE peso", "pregunta que se responde sí o no", "WHERE sin comparación"],
		["SELECT nombre FROM carretas WHERE peso > 4 AND", "Después de AND falta otra condición", "AND a medias"],
		["SELECT nombre FROM carretas peso > 4", "¿Falta WHERE", "falta WHERE"],
		["SELECT nombre FROM carretas WHERE peso > '4'", "Los números van sin comillas", "número entre comillas"],
		["SELECT nombre FROM carretas WHERE color > 4", "se compara el texto", "texto contra número"],
		["SELECT nombre FROM carretas ORDER peso", "ORDER va BY", "ORDER sin BY"],
		["SELECT nombre FROM carretas LIMIT", "Después de LIMIT va un número", "LIMIT sin número"],
		["SELECT nombre FROM carretas ORDER BY peso WHERE peso > 2", "fuera de lugar", "WHERE después de ORDER BY"],
		["SELECT nombre FROM ninos JOIN mascotas", "va ON", "JOIN sin ON"],
		["SELECT nombre FROM ninos LEFT JOIN mascotas ON mascota_id = id", "solo se usa JOIN o INNER JOIN", "LEFT JOIN"],
		["SELECT nombre FROM ninos JOIN carretas ON mascota_id = peso", "está en las dos tablas", "columna repetida en dos tablas"],
		["SELECT gatos.nombre FROM ninos", "no está en la consulta", "tabla que no está en la consulta"],
		["SELECT nombre FROM carretas; SELECT peso FROM carretas", "una sola consulta", "dos consultas"],
		["# hola\nSELECT nombre FROM carretas", "comentarios empiezan con --", "comentario de Python"],
		["SELECT nombre,\nFROM carretas", "Sobra la coma", "coma de más"],
		["SELECT nombre, COUNT(*) FROM carretas", "no se pueden mezclar", "COUNT con columnas"],
	]
	for c in cases:
		var got := _error(String(c[0]))
		check.call(got.contains(String(c[1])), "SQL, error claro: %s (%s)" % [c[2], got])
	check.call(_error("SELECT nombre\nFROM carretas\nWHERE colr = 'gris'").begins_with("Línea 3:"), "SQL: el error dice en qué línea está")


func _compare(check: Callable) -> void:
	var want := _engine.run("SELECT nombre FROM carretas WHERE peso > 10", _tables)
	var same := SqlCheck.compare(_engine.run("select NOMBRE from carretas where peso >= 11", _tables), want, false)
	check.call(same.is_empty(), "Comparar: otra consulta con el mismo resultado también vale")
	var cols := SqlCheck.compare(_engine.run("SELECT * FROM carretas WHERE peso > 10", _tables), want, false)
	check.call(cols.get("key") == "sql_check_columns", "Comparar: SELECT * cuando piden una columna avisa de las columnas")
	var extra := SqlCheck.compare(_engine.run("SELECT nombre FROM carretas WHERE peso >= 10", _tables), want, false)
	check.call(extra.get("key") == "sql_check_extra" and extra.get("row") == "Sal", "Comparar: avisa qué fila sobra")
	var missing := SqlCheck.compare(_engine.run("SELECT nombre FROM carretas WHERE peso > 12", _tables), want, false)
	check.call(missing.get("key") == "sql_check_missing" and missing.get("row") == "Roca", "Comparar: avisa qué fila falta")
	var sorted := _engine.run("SELECT nombre FROM carretas ORDER BY peso", _tables)
	var other := SqlCheck.compare(_engine.run("SELECT nombre FROM carretas", _tables), sorted, true)
	check.call(other.get("key") == "sql_check_order", "Comparar: si importa el orden, avisa que está desordenado")
	var swap := SqlCheck.compare(_engine.run("SELECT peso, nombre FROM carretas", _tables), _engine.run("SELECT nombre, peso FROM carretas", _tables), false)
	check.call(swap.is_empty(), "Comparar: las columnas pueden venir en otro orden")
