## Patrón Strategy: ¿qué palabra de SQL falta en la consulta?
class_name KeywordProblem
extends SqlProblem

const POOL := ["SELECT", "FROM", "WHERE", "ORDER BY", "LIMIT", "JOIN"]

var words: Array = ["SELECT", "FROM"]    # las que puede tapar (chambers.json)


func make(rng: RandomNumberGenerator) -> Dictionary:
	var t := make_table(rng)
	var name: String = t.columns[0]
	var number: String = t.columns[1]
	var lines := {"SELECT": "SELECT %s" % name, "FROM": "FROM %s" % t.name}
	if "WHERE" in words:
		lines["WHERE"] = "WHERE %s > %d" % [number, rng.randi_range(2, 5)]
	if "ORDER BY" in words:
		lines["ORDER BY"] = "ORDER BY %s" % number
	if "LIMIT" in words:
		lines["LIMIT"] = "LIMIT %d" % rng.randi_range(1, 2)
	var hidden: String = words[rng.randi() % words.size()]
	var code: Array = []
	for key in ["SELECT", "FROM", "WHERE", "ORDER BY", "LIMIT"]:
		if lines.has(key):
			var line: String = lines[key]
			code.append(line.replace(key, "_____") if key == hidden else line)
	var pick := choices(hidden, [], POOL.filter(func(w): return w != hidden), rng)
	return problem("quiz_keyword_title", "quiz_keyword_question", [t], code, pick)
