## Poción de corazón (escena: scenes/objetos/pocion.tscn). Aparece en la sala del jefe cada vez
## que cae su escudo. Flota, brilla y tiene dos flechas que rebotan encima para que se vea de
## lejos. Al tocarla, Tala recupera vida (si ya tiene todos los corazones, la poción se queda).
class_name HeartPotion
extends Area2D

signal taken

const GOLD := Color("ffc857")
const PINK := Color("ff5a7a")

@onready var sprite: Sprite2D = $Frasco

var _time := 0.0


func _ready() -> void:
	add_to_group("potions")
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_try_take)


func _process(delta: float) -> void:
	_time += delta
	sprite.position.y = -4.0 + sin(_time * 3.0) * 1.5
	for body in get_overlapping_bodies():
		_try_take(body)
	queue_redraw()


func _try_take(body: Node2D) -> void:
	if body is PlayerController and not is_queued_for_deletion():
		taken.emit()


func _draw() -> void:
	# Un anillo que late en el piso
	var pulse := 0.5 + 0.5 * sin(_time * 5.0)
	draw_arc(Vector2(0, 3), 7.0 + pulse * 3.0, 0.0, TAU, 24, Color(PINK, 0.35 + 0.4 * pulse), 1.0)
	# Tres flechas (arriba, izquierda y derecha) que rebotan apuntando a la poción
	var bounce := absf(sin(_time * 4.0)) * 4.0
	_arrow(Vector2(0, -15.0 - bounce), Vector2.DOWN)
	_arrow(Vector2(-11.0 - bounce, -4.0), Vector2.RIGHT)
	_arrow(Vector2(11.0 + bounce, -4.0), Vector2.LEFT)


## Una flecha con la punta en «tip», apuntando hacia «dir».
func _arrow(tip: Vector2, dir: Vector2) -> void:
	var side := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([tip, tip - dir * 4.5 + side * 3.5, tip - dir * 4.5 - side * 3.5]), GOLD)
	draw_line(tip - dir * 4.5, tip - dir * 9.0, GOLD, 2.0)
