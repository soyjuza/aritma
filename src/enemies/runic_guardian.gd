## El guardián rúnico (escena: scenes/enemigos/runico.tscn): una calavera con aura roja y runas
## que giran a su alrededor. No golpea: cuando se acerca a Tala se carga y explota (estrategia
## RuneBlast). Un golpe de garrote no lo detiene, pero dos lo deshacen. Cae del techo con un
## círculo de runas en vez de la sombra gris, deja una estela roja y grietas rojas al aterrizar.
class_name RunicGuardian
extends Guardian

const RED := Color("ff3b2f")
const EXPLOSION := preload("res://assets/pack/fx/Elemental/Explosion/SpriteSheet.png")

## Alcance de la explosión (px): el círculo rojo del suelo.
@export var blast_radius := 30.0

var _spin := 0.0
var _scorch := 0.0     # grietas rojas del aterrizaje (se apagan)

@onready var _aura: PointLight2D = $Aura


func _make_attack() -> GuardianAttack:
	return RuneBlast.new()


func _physics_process(delta: float) -> void:
	super(delta)
	_spin += delta * (3.0 + 9.0 * charge)
	_scorch = maxf(0.0, _scorch - delta * 0.8)
	_aura.energy = (0.7 + 0.5 * sin(_spin * 2.0) + 1.2 * charge) if sprite.visible else 0.0


func on_windup() -> void:
	if bus:
		bus.publish(GameEvents.GUARDIAN_CHARGING)


func on_landed() -> void:
	_scorch = 1.0


## La explosión del pack, en el lugar del rúnico (se borra sola al terminar).
func explosion_fx() -> void:
	var boom := Sprite2D.new()
	boom.texture = EXPLOSION
	boom.hframes = 9
	boom.position = position + Vector2(0, -8)
	boom.scale = Vector2.ONE * (blast_radius * 2.0 / 40.0)
	boom.z_index = 6
	get_parent().add_child(boom)
	var t := boom.create_tween()
	t.tween_property(boom, "frame", 8, 0.5)
	t.tween_callback(boom.queue_free)
	burst(Vector2(0, -6), "RockGray", 10, 0.7)


func _draw() -> void:
	super()
	if state_name == "dropping" and lift > 1.0:
		_draw_rune_circle(10.0 + 6.0 * (1.0 - lift / 150.0), 0.9)
		if sprite.visible:
			draw_line(Vector2(0, -8 - lift - 34), Vector2(0, -8 - lift), Color(RED, 0.55), 3.0)
		return
	if _scorch > 0.0:
		var a := _scorch
		for line in [[Vector2(-3, 0), Vector2(-9, 3), Vector2(-14, 2)], [Vector2(2, 1), Vector2(8, 4), Vector2(13, 3)], [Vector2(0, 2), Vector2(-2, 7)]]:
			draw_polyline(PackedVector2Array(line), Color(RED, a), 1.0)
	if state_name == "windup":
		# El alcance de la explosión: un círculo que se llena
		draw_circle(Vector2.ZERO, blast_radius, Color(RED, 0.10 + 0.12 * charge))
		draw_arc(Vector2.ZERO, blast_radius, 0, TAU, 40, Color(RED, 0.8), 1.0)
		draw_arc(Vector2.ZERO, blast_radius * charge, 0, TAU, 32, Color(1, 0.75, 0.3, 0.8), 1.0)
	if is_active() and state_name != "dropping":
		# Runas que giran a su alrededor
		for i in 4:
			var at := Vector2.from_angle(_spin + i * TAU / 4.0) * Vector2(9, 4) + Vector2(0, -2 - lift)
			draw_rect(Rect2(at - Vector2(1, 1), Vector2(2, 2)), Color(RED, 0.9))


## Círculo de runas que gira en el suelo (el aviso de su caída).
func _draw_rune_circle(radius: float, alpha: float) -> void:
	draw_arc(Vector2.ZERO, radius, 0, TAU, 28, Color(RED, alpha), 1.0)
	draw_arc(Vector2.ZERO, radius - 3.0, 0, TAU, 24, Color(RED, alpha * 0.6), 1.0)
	for i in 6:
		var at := Vector2.from_angle(_spin + i * TAU / 6.0) * (radius - 1.5)
		draw_rect(Rect2(at - Vector2(1, 1), Vector2(2, 2)), Color(1, 0.8, 0.4, alpha))
