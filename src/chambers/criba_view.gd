## Dibujo de la Criba. La lógica está en CribaMachine.
class_name CribaView
extends RefCounted


static func draw_board(ci: CanvasItem, gate_open: float, round_lit: Array, filled: int, time: float) -> void:
	# Tablero
	_box(ci, Rect2(-104, -82, 196, 62), CribaMachine.STONE_DARK)
	_box(ci, Rect2(-100, -78, 188, 54), CribaMachine.STONE)
	ci.draw_rect(Rect2(-100, -78, 188, 3), CribaMachine.STONE_LIGHT)
	ci.draw_rect(Rect2(-104, -24, 196, 4), CribaMachine.BRONZE_DARK)
	ci.draw_rect(Rect2(-104, -84, 196, 3), CribaMachine.BRONZE)
	# Lámparas
	for i in round_lit.size():
		var c := Vector2(58 + i * 9, -71)
		ci.draw_circle(c, 3.5, CribaMachine.OUTLINE)
		ci.draw_circle(c, 2.5, CribaMachine.GOLD if round_lit[i] else Color("2a3036"))
	# Tolva
	var hopper := PackedVector2Array([Vector2(-102, -64), Vector2(-78, -64), Vector2(-84, -48), Vector2(-96, -48)])
	ci.draw_colored_polygon(hopper, CribaMachine.BRONZE)
	ci.draw_polyline(hopper + PackedVector2Array([hopper[0]]), CribaMachine.OUTLINE, 1.0)
	# Canal
	ci.draw_rect(Rect2(-90, CribaMachine.CHANNEL_Y - 8, CribaMachine.GATE.x + 98, 16), CribaMachine.OUTLINE)
	ci.draw_rect(Rect2(-89, CribaMachine.CHANNEL_Y - 7, CribaMachine.GATE.x + 96, 14), Color("1a2b30"))
	ci.draw_rect(Rect2(-89, CribaMachine.CHANNEL_Y - 7, CribaMachine.GATE.x + 96, 14), CribaMachine.GLASS)
	ci.draw_rect(Rect2(-89, CribaMachine.CHANNEL_Y - 6, CribaMachine.GATE.x + 96, 1), Color(1, 1, 1, 0.35))
	# Compuerta
	var tilt := gate_open * 0.5
	var g1 := CribaMachine.SPLIT + Vector2(-9, 0).rotated(tilt)
	var g2 := CribaMachine.SPLIT + Vector2(9, 0).rotated(tilt)
	ci.draw_line(CribaMachine.GATE + Vector2(0, 8), CribaMachine.SPLIT, CribaMachine.OUTLINE, 3.0)
	ci.draw_line(g1, g2, CribaMachine.OUTLINE, 4.0)
	ci.draw_line(g1, g2, CribaMachine.BRONZE, 2.0)
	# Canaletas
	for side in [-1.0, 1.0]:
		var target: Vector2 = CribaMachine.CHALICE if side < 0 else CribaMachine.CRUCIBLE
		var from: Vector2 = CribaMachine.SPLIT + Vector2(side * 8, 3)
		var to: Vector2 = target + Vector2(-side * 4, -12)
		ci.draw_line(from, to, CribaMachine.OUTLINE, 5.0)
		ci.draw_line(from, to, CribaMachine.BRONZE_DARK, 3.0)
	# Cáliz
	var cup := CribaMachine.CHALICE
	ci.draw_rect(Rect2(cup.x - 2, cup.y - 2, 4, 8), CribaMachine.OUTLINE)
	ci.draw_rect(Rect2(cup.x - 6, cup.y + 4, 12, 3), CribaMachine.OUTLINE)
	ci.draw_rect(Rect2(cup.x - 5, cup.y + 4, 10, 2), CribaMachine.BRONZE)
	var bowl := PackedVector2Array([Vector2(-10, -14), Vector2(10, -14), Vector2(6, -3), Vector2(-6, -3)])
	for i in bowl.size():
		bowl[i] += cup
	ci.draw_colored_polygon(bowl, CribaMachine.GOLD.darkened(0.15))
	ci.draw_polyline(bowl + PackedVector2Array([bowl[0]]), CribaMachine.OUTLINE, 1.0)
	var fill := clampf(filled / 12.0, 0.0, 1.0)
	ci.draw_rect(Rect2(cup.x - 8, cup.y - 13, 16, 2), CribaMachine.GOLD.lightened(0.3 * fill))
	# Crisol
	var pot := CribaMachine.CRUCIBLE
	ci.draw_rect(Rect2(pot.x - 11, pot.y - 14, 22, 15), CribaMachine.OUTLINE)
	ci.draw_rect(Rect2(pot.x - 10, pot.y - 13, 20, 13), Color("3a3330"))
	ci.draw_rect(Rect2(pot.x - 8, pot.y - 13, 16, 3), CribaMachine.RED.lerp(Color("ffb347"), 0.5 + 0.5 * sin(time * 7.0)))
	ci.draw_rect(Rect2(pot.x - 12, pot.y - 15, 24, 2), CribaMachine.BRONZE_DARK)




static func _box(ci: CanvasItem, r: Rect2, color: Color) -> void:
	ci.draw_rect(r.grow(1), CribaMachine.OUTLINE)
	ci.draw_rect(r, color)
