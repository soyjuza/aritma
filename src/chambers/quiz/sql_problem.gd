## Patrón Strategy: base de los problemas de SQL. Inventa tablas chicas, corre la consulta
## en SqlEngine para saber la respuesta y arma las opciones con consultas parecidas pero equivocadas.
class_name SqlProblem
extends QuizProblem

const THEMES := {
	"gatos": {"columns": ["nombre", "edad", "color"], "names": ["Luna", "Tom", "Mia", "Coco", "Nube", "Toby", "Kiwi", "Lola"], "colors": ["negro", "blanco", "gris"], "max": 12},
	"frutas": {"columns": ["nombre", "precio", "color"], "names": ["uva", "pera", "kiwi", "mango", "fresa", "lima", "piña", "coco"], "colors": ["roja", "verde", "amarilla"], "max": 9},
	"robots": {"columns": ["nombre", "pilas", "color"], "names": ["Bip", "Zap", "Chispa", "Perno", "Rayo", "Volt", "Gira", "Pixel"], "colors": ["azul", "rojo", "plata"], "max": 9},
}

var options := 4
var rows := 4

var _engine := SqlEngine.new()


## Una tabla de un tema al azar: nombre, un número (sin repetir) y un color.
func make_table(rng: RandomNumberGenerator) -> SqlTable:
	var keys := THEMES.keys()
	var name: String = keys[rng.randi() % keys.size()]
	var theme: Dictionary = THEMES[name]
	var names := shuffled(theme.names, rng).slice(0, rows)
	var numbers := shuffled(range(1, int(theme.max) + 1), rng).slice(0, rows)
	var data: Array = []
	for k in rows:
		data.append([names[k], numbers[k], theme.colors[rng.randi() % theme.colors.size()]])
	return SqlTable.new(name, theme.columns, data)


## Lo que trae la consulta, como texto: "Luna, Tom" (la primera columna).
func run_text(query: String, tables: Array) -> String:
	var result := _engine.run(query, tables)
	assert(result.ok, "Consulta del problema con error: %s (%s)" % [query, result.error])
	if result.rows.is_empty():
		return say("quiz_sql_none")
	return ", ".join(result.rows.map(func(r): return SqlEngine.show(r[0])))


func run_count(query: String, tables: Array) -> int:
	return _engine.run(query, tables).rows.size()


## {options, answer} con la respuesta y las opciones equivocadas (sin repetir).
func choices(right: String, wrong: Array, extra: Array, rng: RandomNumberGenerator) -> Dictionary:
	var out := [right]
	for w in wrong + shuffled(extra, rng):
		if out.size() < options and not String(w) in out:
			out.append(String(w))
	out = shuffled(out, rng)
	return {"options": out, "answer": out.find(right)}


## Listas de nombres que no son la respuesta, para completar opciones.
func name_lists(t: SqlTable, rng: RandomNumberGenerator) -> Array:
	var names := t.rows.map(func(r): return String(r[0]))
	var out: Array = []
	for i in 6:
		var pick := shuffled(names, rng).slice(0, rng.randi_range(1, names.size() - 1))
		var ordered := names.filter(func(n): return n in pick)
		out.append(", ".join(ordered))
	return out


func problem(title_key: String, question_key: String, tables: Array, code: Array, pick: Dictionary, params := {}) -> Dictionary:
	return {
		"title": say(title_key),
		"question": say(question_key, params),
		"tables": tables.map(func(t): return t.to_data()),
		"code": code,
		"options": pick.options,
		"answer": pick.answer,
	}


static func shuffled(list: Array, rng: RandomNumberGenerator) -> Array:
	var copy := list.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy
