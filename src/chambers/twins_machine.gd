@tool
## Los Árboles Gemelos (capítulo 5, INNER JOIN y WHERE). Cada niño cuida un árbol; hay que
## juntar las dos tablas y quedarse con los niños de los árboles de manzanas.
class_name TwinsMachine
extends SqlMachine

const KIDS := ["Ana", "Beto", "Coco", "Dani", "Eva", "Fede", "Gabi", "Hana"]
const FRUITS := ["manzana", "pera", "naranja"]


## 3 árboles (siempre uno de manzanas) y 5 niños.
func make_tables(_i: int) -> Array:
	var fruits := FRUITS.duplicate()
	fruits.shuffle()
	var trees: Array = []
	for id in range(1, 4):
		trees.append([id, fruits[id - 1]])
	var apple := fruits.find("manzana") + 1
	var kids: Array = []
	var names := _names(KIDS, 5)
	for k in 5:
		kids.append([names[k], apple if k < 2 else _rng.randi_range(1, 3)])
	kids.shuffle()
	return [SqlTable.new("ninos", ["nombre", "arbol_id"], kids), SqlTable.new("arboles", ["id", "fruta"], trees)]


func _draw() -> void:
	# Dos árboles gemelos; los nombres que trajo la consulta cuelgan como frutas
	var names := got_values("nombre").map(func(v): return SqlEngine.show(v))
	for side in [-1, 1]:
		var base := Vector2(side * 26, -6)
		draw_rect(Rect2(base + Vector2(-3, -30), Vector2(6, 30)), WOOD_DARK)
		draw_circle(base + Vector2(0, -38), 13.0, OUTLINE)
		draw_circle(base + Vector2(0, -38), 12.0, LEAF if mark != BAD else Color("8a7a3a"))
		for k in 3:
			draw_line(base, base + Vector2(-8 + k * 8, 8), WOOD, 1.0)
	for i in mini(names.size(), 4):
		var at := Vector2(-26 + (i % 2) * 52 + (-6 if i < 2 else 6), -42 + (i / 2) * 9)
		draw_circle(at, 3.0, BAD)
		_text_center(names[i], at + Vector2(0, -4), 5, mark if mark.a > 0.0 else Color.WHITE)
	_draw_tables({"ninos": "nombre"}, -56)
	if mark.a > 0.0:
		draw_rect(Rect2(-50, -54, 100, 56), mark, false, 2.0)
