@tool
## El Jardín de las Macetas (capítulo 2, WHERE con textos). Riega las macetas que trae
## la consulta: las de tierra 'seca'.
class_name GardenMachine
extends SqlMachine

const FLOWERS := ["Rosa", "Lirio", "Tulipán", "Clavel", "Dalia", "Girasol", "Violeta", "Orquídea"]
const DRY := Color("c8a06a")
const WET := Color("5a3a24")


## 4 o 5 macetas, siempre con secas y mojadas.
func make_tables(_i: int) -> Array:
	var count := _rng.randi_range(4, 5)
	var names := _names(FLOWERS, count)
	var soils: Array = ["seca", "mojada"]
	while soils.size() < count:
		soils.append("seca" if _rng.randf() < 0.5 else "mojada")
	soils.shuffle()
	var rows: Array = []
	for k in count:
		rows.append([names[k], soils[k], _rng.randi_range(1, 6)])
	return [SqlTable.new("macetas", ["nombre", "tierra", "hojas"], rows)]


func _draw() -> void:
	var pots := table("macetas")
	if pots == null:
		return
	var watered := got_values("nombre").map(func(v): return SqlEngine.show(v))
	var n := pots.rows.size()
	for k in n:
		var x := -((n - 1) * 24) / 2.0 + k * 24
		var row: Array = pots.rows[k]
		var pot := PackedVector2Array([Vector2(x - 9, -16), Vector2(x + 9, -16), Vector2(x + 6, 0), Vector2(x - 6, 0)])
		draw_colored_polygon(pot, Color("b0603a"))
		draw_polyline(pot + PackedVector2Array([pot[0]]), OUTLINE, 1.0)
		draw_rect(Rect2(x - 10, -19, 20, 4), WET if String(row[1]) == "mojada" else DRY)
		var wet := String(row[0]) in watered
		var leaf := LEAF if wet or String(row[1]) == "mojada" else Color("8a7a3a")
		draw_line(Vector2(x, -19), Vector2(x, -32), leaf.darkened(0.2), 2.0)
		draw_circle(Vector2(x - 4, -28), 3.5, leaf)
		draw_circle(Vector2(x + 4, -31), 3.5, leaf)
		if wet:
			for i in 3:
				draw_circle(Vector2(x - 5 + i * 5, -40 + (i % 2) * 3), 1.4, CYAN)
	_draw_tables({"macetas": "nombre"}, -48)
	if mark.a > 0.0:
		draw_rect(Rect2(-((n - 1) * 24) / 2.0 - 16, -46, (n - 1) * 24 + 32, 48), mark, false, 2.0)
