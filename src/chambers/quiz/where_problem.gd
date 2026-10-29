## Patrón Strategy: ¿qué filas deja pasar el WHERE? Con logic, la condición lleva AND u OR.
class_name WhereProblem
extends SqlProblem

const FLIP := {">": "<", "<": ">"}

var logic := 0    # 1: dos condiciones con AND u OR
var count := 0    # 1: pregunta cuántas filas trae


func make(rng: RandomNumberGenerator) -> Dictionary:
	var t := make_table(rng)
	var name: String = t.columns[0]
	var number: String = t.columns[1]
	var color: String = t.columns[2]
	var values := t.rows.map(func(r): return int(r[1]))
	values.sort()
	var op: String = [">", "<"][rng.randi() % 2]
	var k: int = values[rng.randi_range(1, values.size() - 2)]
	var first := "%s %s %d" % [number, op, k]
	var where := first
	var wrong_conditions := ["%s %s %d" % [number, FLIP[op], k], "%s %s= %d" % [number, op, k]]
	if logic > 0:
		var paint: String = t.rows[rng.randi() % t.rows.size()][2]
		var second := "%s = '%s'" % [color, paint]
		var joiner: String = ["AND", "OR"][rng.randi() % 2]
		var other: String = "OR" if joiner == "AND" else "AND"
		where = "%s %s %s" % [first, joiner, second]
		wrong_conditions = ["%s %s %s" % [first, other, second], second, first]
	elif rng.randf() < 0.35:
		# A veces con un texto: color = 'gris'
		var paint: String = t.rows[rng.randi() % t.rows.size()][2]
		where = "%s = '%s'" % [color, paint]
		wrong_conditions = ["%s <> '%s'" % [color, paint], first]
	var query := "SELECT %s FROM %s WHERE %s" % [name, t.name, where]
	var code := ["SELECT %s" % name, "FROM %s" % t.name, "WHERE %s" % where]
	if count > 0:
		var right := run_count(query, [t])
		var wrong: Array = wrong_conditions.map(func(c): return run_count("SELECT %s FROM %s WHERE %s" % [name, t.name, c], [t]))
		return problem("quiz_where_title", "quiz_rows_question", [t], code, QuizProblem.pick(right, wrong + [rows], options))
	var right_text := run_text(query, [t])
	var wrong_text: Array = wrong_conditions.map(func(c): return run_text("SELECT %s FROM %s WHERE %s" % [name, t.name, c], [t]))
	wrong_text.append(run_text("SELECT %s FROM %s" % [name, t.name], [t]))
	var pick := choices(right_text, wrong_text, name_lists(t, rng), rng)
	return problem("quiz_where_title", "quiz_where_question", [t], code, pick)
