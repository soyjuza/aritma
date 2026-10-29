## Patrón Strategy: ¿qué muestra un SELECT? (o ¿cuántas columnas trae?)
class_name SelectProblem
extends SqlProblem

var count := 0    # 1: pregunta cuántas columnas


func make(rng: RandomNumberGenerator) -> Dictionary:
	var t := make_table(rng)
	if count > 0:
		return _count(t, rng)
	var columns := shuffled(t.columns, rng)
	var shown: String = columns[0]
	var query := "SELECT %s FROM %s" % [shown, t.name]
	var right := run_text(query, [t])
	var wrong: Array = []
	for other in columns.slice(1):
		wrong.append(run_text("SELECT %s FROM %s" % [other, t.name], [t]))
	wrong.append(", ".join(right.split(", ").slice(0, 2)))
	var pick := choices(right, wrong, [], rng)
	return problem("quiz_select_title", "quiz_select_question", [t], ["SELECT %s" % shown, "FROM %s" % t.name], pick)


func _count(t: SqlTable, rng: RandomNumberGenerator) -> Dictionary:
	var how := rng.randi_range(1, 3)
	var picked := shuffled(t.columns, rng).slice(0, how)
	var head := "SELECT *" if how == 3 and rng.randf() < 0.5 else "SELECT " + ", ".join(picked)
	var right := t.columns.size() if head == "SELECT *" else how
	var pick := QuizProblem.pick(right, [rows, 1, 2, 3], options)
	return problem("quiz_select_title", "quiz_columns_question", [t], [head, "FROM %s" % t.name], pick)
