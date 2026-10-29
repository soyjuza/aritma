## Patrón Strategy: dos tablas unidas con JOIN. ¿Qué mascota tiene alguien?
## Con count: ¿cuántas filas trae el INNER JOIN? (hay niños sin mascota).
class_name JoinProblem
extends SqlProblem

const KIDS := ["Ana", "Beto", "Coco", "Dani", "Eva", "Fede", "Gabi", "Hana"]
const PETS := ["perro", "gato", "loro", "pez", "conejo", "tortuga"]

var count := 0


func make(rng: RandomNumberGenerator) -> Dictionary:
	var pets := shuffled(PETS, rng).slice(0, 3)
	var pet_rows: Array = []
	for i in pets.size():
		pet_rows.append([i + 1, pets[i]])
	var kids := shuffled(KIDS, rng).slice(0, 4)
	var without := rng.randi_range(1, 2) if count > 0 else 0
	var kid_rows: Array = []
	for i in kids.size():
		# mascota_id 0 no está en la tabla mascotas: ese niño no tiene pareja
		kid_rows.append([kids[i], 0 if i < without else rng.randi_range(1, 3)])
	kid_rows = shuffled(kid_rows, rng)
	var tables := [SqlTable.new("ninos", ["nombre", "mascota_id"], kid_rows), SqlTable.new("mascotas", ["id", "animal"], pet_rows)]
	var on := "ON ninos.mascota_id = mascotas.id"
	if count > 0:
		var right := run_count("SELECT ninos.nombre FROM ninos INNER JOIN mascotas " + on, tables)
		var pick := QuizProblem.pick(right, [kid_rows.size(), pet_rows.size(), right - 1], options)
		return problem("quiz_join_title", "quiz_rows_question", tables, ["SELECT ninos.nombre", "FROM ninos", "INNER JOIN mascotas", on], pick)
	var who: String = kid_rows[rng.randi() % kid_rows.size()][0]
	var right := run_text("SELECT mascotas.animal FROM ninos JOIN mascotas %s WHERE ninos.nombre = '%s'" % [on, who], tables)
	var pick := choices(right, pets.filter(func(p): return p != right), PETS, rng)
	return problem("quiz_join_title", "quiz_join_question", tables, ["SELECT mascotas.animal", "FROM ninos", "JOIN mascotas", on, "WHERE ninos.nombre = '%s'" % who], pick, {"name": who})
