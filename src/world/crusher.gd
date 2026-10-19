@tool
## Prensa de piedra: dos bloques salen de los muros y se juntan en el centro del pasillo,
## una y otra vez, con un ritmo fijo. Si atrapan a Tala, la devuelven al último punto seguro.
## Una lámpara se pone roja justo antes de cerrar (así se puede leer el ritmo).
class_name Crusher
extends Node2D

signal crushed

const OUTLINE := Color("14181c")
const STONE := Color("4a5a50")
const STONE_LIGHT := Color("7a8c80")
const BRONZE := Color("b48a4e")

## Se ajustan en el Inspector; el ritmo (period) lo pueden cambiar los datos de la sala.
@export var half_width := 40.0      # ancho del pasillo / 2 (px)
@export var depth := 14.0           # alto de la prensa (px)
@export var period := 2.4
@export var phase := 0.0
@export var closed_part := 0.35     # fracción del ciclo en que está cerrada (o cerrándose)

var _time := 0.0
var _hit := false


## Cuánto salió cada bloque (0 = metido en el muro, 1 = juntos en el centro).
func extension() -> float:
	var k := fposmod(_time / period + phase, 1.0)
	var close_at := 1.0 - closed_part
	if k < close_at:
		return 0.0
	# Sale rápido, se queda un instante y vuelve
	var c := (k - close_at) / closed_part
	if c < 0.25:
		return c / 0.25
	if c < 0.7:
		return 1.0
	return 1.0 - (c - 0.7) / 0.3


func warning() -> bool:
	var k := fposmod(_time / period + phase, 1.0)
	return k > 1.0 - closed_part - 0.18 and k < 1.0 - closed_part


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()
	var player: PlayerController = get_tree().get_first_node_in_group("player")
	if player == null or player.falling:
		_hit = false
		return
	var local := to_local(player.global_position)
	var reach := extension() * half_width
	var inside_y := absf(local.y + 3.0) < depth / 2.0 + 3.0
	var caught := inside_y and (local.x < -half_width + reach + 4.0 or local.x > half_width - reach - 4.0)
	if caught and reach > 2.0 and not _hit:
		_hit = true
		crushed.emit()
	elif not caught:
		_hit = false


func _draw() -> void:
	var reach := extension() * half_width
	for side in [-1.0, 1.0]:
		var outer: float = side * (half_width + 8.0)
		var inner: float = side * (half_width - reach)
		var r := Rect2(minf(outer, inner), -depth / 2.0, absf(outer - inner), depth)
		draw_rect(r.grow(1), OUTLINE)
		draw_rect(r, STONE)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), STONE_LIGHT)
		# Cara de bronce con dientes
		var face_x: float = inner - side * 3.0
		draw_rect(Rect2(minf(face_x, inner), -depth / 2.0, 3.0, depth), BRONZE)
	# Lámparas de aviso en los muros
	var lamp := Color("ff5a4e") if warning() or extension() > 0.0 else Color("3a2a2a")
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * (half_width + 4.0), -depth / 2.0 - 4.0), 2.5, OUTLINE)
		draw_circle(Vector2(side * (half_width + 4.0), -depth / 2.0 - 4.0), 1.8, lamp)
