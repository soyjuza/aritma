## Objeto de una misión (engranaje de Brasa, hongo de Lía). Se recoge al tocarlo.
class_name GearPickup
extends Area2D

signal taken

const BRONZE := Color("d8a25a")
const DARK := Color("7a5a2e")
const OUTLINE := Color("14181c")

@export var item_id := ""
@export var quest_id := "engranajes"
@export var look := "gear"     # "gear" o "mushroom"

var _time := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_try_take)
	if look == "mushroom" and has_node("Luz"):
		var luz := $Luz as PointLight2D
		luz.color = Color("7fe8ff")
		luz.energy = 0.4
		luz.texture_scale = 0.2


func _process(delta: float) -> void:
	_time += delta
	for body in get_overlapping_bodies():
		_try_take(body)
	queue_redraw()


func _try_take(body: Node2D) -> void:
	if body is PlayerController and not is_queued_for_deletion():
		taken.emit()


func _draw() -> void:
	var c := Vector2(0, -5.0 + sin(_time * 3.0) * 1.5)
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	draw_arc(Vector2(0, 3), 7.0 + pulse * 2.0, 0.0, TAU, 24, Color(BRONZE, 0.25 + 0.35 * pulse), 1.0)
	if look == "mushroom":
		_draw_mushroom(c, pulse)
		return
	# Rueda con 8 dientes que gira
	var points := PackedVector2Array()
	for i in 32:
		var a := _time * 1.2 + i * TAU / 32.0
		var r := 6.5 if (i / 2) % 2 == 0 else 4.8
		points.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(points, BRONZE)
	draw_polyline(points + PackedVector2Array([points[0]]), OUTLINE, 1.0)
	draw_circle(c, 2.6, DARK)
	draw_circle(c, 1.2, OUTLINE)


## Hongo luminoso del Bosque.
func _draw_mushroom(c: Vector2, pulse: float) -> void:
	draw_rect(Rect2(c + Vector2(-2, -1), Vector2(4, 7)), Color("e8dcc0"))
	var cap := PackedVector2Array()
	for i in 13:
		var a := PI + i * PI / 12.0
		cap.append(c + Vector2(cos(a) * 7.0, sin(a) * 6.0))
	draw_colored_polygon(cap, Color("3fe0ff").lerp(Color("8affc8"), pulse))
	draw_polyline(cap + PackedVector2Array([cap[0]]), OUTLINE, 1.0)
	draw_circle(c + Vector2(-3, -3), 1.2, Color.WHITE)
	draw_circle(c + Vector2(2, -4), 1.0, Color.WHITE)