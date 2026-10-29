## Patrón Strategy: ¿en qué orden salen las filas con ORDER BY? Con limit, además LIMIT.
class_name SortProblem
extends SqlProblem

var limit := 0    # 1: la consulta termina con LIMIT


func make(rng: RandomNumberGenerator) -> Dictionary:
	var t := make_table(rng)
	var name: String = t.columns[0]
	var number: String = t.columns[1]
	var desc := rng.randf() < 0.5
	var order := "ORDER BY %s%s" % [number, " DESC" if desc else ""]
	var other := "ORDER BY %s%s" % [number, "" if desc else " DESC"]
	var tail := " LIMIT %d" % rng.randi_range(1, 2) if limit > 0 else ""
	var base := "SELECT %s FROM %s " % [name, t.name]
	var right := run_text(base + order + tail, [t])
	var wrong: Array = [run_text(base + other + tail, [t])]
	wrong.append(run_text(base + order, [t]) if limit > 0 else run_text(base.strip_edges(), [t]))
	wrong.append(run_text("SELECT %s FROM %s ORDER BY %s%s" % [name, t.name, name, tail], [t]))
	var code := ["SELECT %s" % name, "FROM %s" % t.name, order]
	if limit > 0:
		code.append(tail.strip_edges())
	var pick := choices(right, wrong, name_lists(t, rng), rng)
	return problem("quiz_order_by_title", "quiz_order_by_question", [t], code, pick)
