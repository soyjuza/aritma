@tool
## La red de la Singularidad (Sala 5): el abismo, las plataformas flotantes numeradas, las
## conexiones de luz entre ellas y los puentes de piedra que se levantan siguiendo un camino.
## Las plataformas son los Marker2D hijos (P0, P1...: se mueven en el editor); la primera es
## el inicio y la última, la del núcleo. Los puentes aparecen uno tras otro y cada uno dura
## poco: hay que correr. Fuera de las plataformas y de los puentes levantados, se cae.
class_name SkyNetwork
extends Node2D

const OUTLINE := Color("101418")
const STONE := Color("6b6478")
const STONE_LIGHT := Color("938aa6")
const STONE_DARK := Color("443f52")
const CYAN := Color("3fe0ff")
const GOLD := Color("ffc857")
const GREEN := Color("6be38b")
const RED := Color("ff5a4e")

## La zona del abismo (en coordenadas de este nodo): fuera de ella el piso es firme.
@export var void_rect := Rect2(24, 56, 448, 180):
	set(value):
		void_rect = value
		queue_redraw()
@export var platform_radius := 13.0
@export var bridge_width := 12.0

var rules: NetworkRules             # la red que se muestra
var highlight: Array = []           # camino resaltado (pruebas de la consola)
var highlight_ok := true
var core_taken := false

var _bridges: Array = []            # [{a, b, start, end}] en segundos desde que se levantaron
var _raised_at := -1.0
var _time := 0.0
var _font: Font = load(UIKit.PIXEL_FONT)


func positions() -> Array:
	var out: Array = []
	for child in get_children():
		if child is Marker2D:
			out.append(child.position)
	return out


## Las plataformas en el orden de sus números (en cada red los números cambian).
func _pos() -> Array:
	return rules.positions if rules and rules.count() == positions().size() else positions()


func start_id() -> int:
	return rules.start if rules else 0


func goal_id() -> int:
	return rules.goal if rules else positions().size() - 1


func platform_global(id: int) -> Vector2:
	return to_global(_pos()[id])


## Muestra una red (la de la sala o una de prueba) y, si se da, un camino resaltado.
func show_network(net: NetworkRules, path: Array = [], ok := true) -> void:
	rules = net
	highlight = path
	highlight_ok = ok
	queue_redraw()


## Levanta los puentes del camino: aparecen uno tras otro y cada uno dura "life" segundos
## (life <= 0: quedan para siempre).
func raise(path: Array, first_delay: float, interval: float, life: float) -> void:
	_bridges.clear()
	for i in range(1, path.size()):
		var t := first_delay + (i - 1) * interval
		_bridges.append({"a": path[i - 1], "b": path[i], "start": t, "end": t + life if life > 0.0 else INF})
	_raised_at = _time


## Los puentes se derrumban todos (Tala cayó o se acabó el tiempo).
func collapse() -> void:
	_bridges.clear()
	_raised_at = -1.0


func bridges_up() -> bool:
	return _raised_at >= 0.0 and not _bridges.is_empty()


## ¿Hay piso firme en este punto (del mundo)?
func is_ground(world: Vector2) -> bool:
	var p := to_local(world)
	if not void_rect.has_point(p):
		return true
	var pos := _pos()
	for q in pos:
		if p.distance_to(q) <= platform_radius + 1.0:
			return true
	var now := _time - _raised_at
	for b in _bridges:
		if now >= b.start + 0.15 and now <= b.end:
			var closest := Geometry2D.get_closest_point_to_segment(p, pos[b.a], pos[b.b])
			if p.distance_to(closest) <= bridge_width / 2.0 + 1.0:
				return true
	return false


func _process(delta: float) -> void:
	_time += delta
	if _raised_at >= 0.0 and not _bridges.is_empty() and _time - _raised_at > _bridges[-1].end + 0.1:
		collapse()
	queue_redraw()


# ------------------------------------------------------------------ dibujo

func _draw() -> void:
	_draw_void()
	var pos := _pos()
	if rules and rules.count() == pos.size():
		for e in rules.edges:
			_draw_link(pos[e[0]], pos[e[1]])
		for i in range(1, highlight.size()):
			var a = highlight[i - 1]
			var b = highlight[i]
			if typeof(a) == TYPE_INT and typeof(b) == TYPE_INT and a >= 0 and b >= 0 and a < pos.size() and b < pos.size():
				draw_line(pos[a], pos[b], Color(GREEN if highlight_ok else RED, 0.9), 3.0)
	var now := _time - _raised_at
	for b in _bridges:
		_draw_bridge(pos[b.a], pos[b.b], now, b.start, b.end)
	for i in pos.size():
		_draw_platform(pos[i], i)


func _draw_void() -> void:
	draw_rect(void_rect.grow(2), OUTLINE)
	draw_rect(void_rect, Color("07060d"))
	# Remolino del vórtice y polvo de estrellas
	var c := void_rect.get_center()
	for k in 5:
		var r := 30.0 + k * 34.0
		draw_arc(c, r, _time * (0.3 + k * 0.07), _time * (0.3 + k * 0.07) + PI * 1.2, 40, Color(0.45, 0.3, 0.9, 0.10), 2.0)
	for k in 40:
		var x := fmod(k * 97.3 + _time * (4.0 + k % 5), void_rect.size.x)
		var y := fmod(k * 53.7 + k * k * 1.3, void_rect.size.y)
		var a := 0.25 + 0.25 * sin(_time * 2.0 + k)
		draw_rect(Rect2(void_rect.position + Vector2(x, y), Vector2(1, 1)), Color(0.8, 0.85, 1.0, a))


func _draw_link(a: Vector2, b: Vector2) -> void:
	var length := a.distance_to(b)
	var dir := (b - a) / maxf(length, 0.01)
	var d := fmod(_time * 12.0, 8.0)
	while d < length:
		draw_line(a + dir * d, a + dir * minf(d + 4.0, length), Color(CYAN, 0.45), 1.0)
		d += 8.0


func _draw_bridge(a: Vector2, b: Vector2, now: float, start: float, end: float) -> void:
	if now < start or now > end:
		return
	var grow := clampf((now - start) / 0.15, 0.0, 1.0)
	var fading := now > end - 0.8
	var alpha := 1.0 if not fading or int(now * 10.0) % 2 == 0 else 0.45
	var dir := (b - a).normalized()
	var side := dir.orthogonal() * bridge_width / 2.0
	var tip := a.lerp(b, grow)
	var plank := PackedVector2Array([a + side, tip + side, tip - side, a - side])
	draw_colored_polygon(plank, Color(STONE_LIGHT if not fading else RED.lerp(STONE_LIGHT, 0.5), alpha))
	draw_polyline(plank + PackedVector2Array([plank[0]]), Color(OUTLINE, alpha), 1.0)
	var steps := int(a.distance_to(tip) / 6.0)
	for k in steps:
		var p := a + dir * (k * 6.0 + 3.0)
		draw_line(p + side * 0.9, p - side * 0.9, Color(STONE_DARK, alpha), 1.0)


func _draw_platform(p: Vector2, id: int) -> void:
	var r := platform_radius
	draw_circle(p + Vector2(0, 3), r, Color(0, 0, 0, 0.5))
	draw_circle(p, r + 1.0, OUTLINE)
	draw_circle(p, r, STONE)
	draw_arc(p, r - 1.0, PI, TAU, 16, STONE_LIGHT, 2.0)
	var ring := CYAN
	if id == start_id():
		ring = GREEN
	elif id == goal_id():
		ring = GOLD
	draw_arc(p, r - 3.0, 0, TAU, 24, Color(ring, 0.55), 1.0)
	if id == goal_id() and not core_taken:
		var pulse := 0.5 + 0.5 * sin(_time * 3.0)
		draw_circle(p + Vector2(0, -6), 6.0 + pulse, Color(GOLD, 0.25))
		draw_circle(p + Vector2(0, -6), 4.0, Color("fff2c0"))
		draw_circle(p + Vector2(-1, -7), 1.5, Color.WHITE)
	else:
		_text_center(str(id), p + Vector2(0, 3), 8, Color("e9f7ff"))


func _text_center(text: String, at: Vector2, size: int, color: Color) -> void:
	var big := size * 2
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
	draw_set_transform(at.round(), 0.0, Vector2(0.5, 0.5))
	draw_string_outline(_font, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, big, 4, OUTLINE)
	draw_string(_font, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, big, color)
	draw_set_transform(Vector2.ZERO)
