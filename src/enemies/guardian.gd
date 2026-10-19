## Guardián de la tumba (escenas: scenes/enemigos/centinela.tscn, el caballero dorado, y
## hechicero.tscn, que ataca de lejos). Duerme como estatua sobre su pedestal o cae del techo
## cuando la alarma sube; despierto, ataca en formación: los de cuerpo a cuerpo rodean a Tala
## desde lados distintos y cuidan a los de distancia; los de distancia mantienen la distancia.
## Cada tipo lleva un aro de color en el suelo para reconocerlo de un vistazo.
## Contexto del patrón State: cada paso de física delega en su estado (dormido, despertando,
## cayendo, persiguiendo, preparando, golpeando, aturdido, vencido). Cómo ataca lo decide su
## estrategia (patrón Strategy: GuardianAttack).
class_name Guardian
extends CharacterBody2D

signal defeated(guardian: Guardian)

const STONE_SHADER := preload("res://assets/efectos/piedra.gdshader")

## Empieza como estatua sobre su pedestal (se ajusta en el Inspector).
@export var dormant := false
## Nombre del tipo (para la alarma del HUD).
@export var kind := "caballero"
## Cómo ataca: "golpe" (cuerpo a cuerpo) u "orbe" (lanza orbes desde lejos).
@export_enum("golpe", "orbe") var attack_kind := "golpe"
## Color del aro del suelo que distingue a cada tipo.
@export var ring_color := Color(1.0, 0.78, 0.25)
## Tamaño del dibujo (1.5 = más imponente que Tala).
@export var body_scale := 1.0
## De distancia: se queda lejos de Tala y dispara cuando la tiene a tiro.
@export var keep_distance := 80.0
@export var shot_range := 125.0
@export var max_hp := 3
@export var damage := 1               # mitades de corazón por golpe
@export var speed := 38.0
@export var reach := 14.0
@export var pedestal_height := 7.0
## Un golpe de garrote lo aturde y le cancela el ataque (el rúnico no: sigue cargando).
@export var staggers := true

var radius := 6.0
var hp := 3
var speed_scale := 1.0                # lo sube la alarma
var facing := Vector2.DOWN
var attack: GuardianAttack
var bus: EventBus
var kit: TileKit
var settings: Dictionary = {}         # sección "combat" de config.json
var from_ceiling := false             # cayó del techo: al vencerlo se borra
var state_name := ""
var lift := 0.0                       # altura del dibujo sobre el suelo (pedestal, caída)
var cooldown := 0.0
var cracks := 0.0                     # 0..1: grietas de la piedra al despertar
var glow := 0.0                       # 0..1: brillo de aviso antes de golpear
var stone := 0.0                      # 1 = piedra gris, 0 = color vivo
var shake := 0.0                      # temblor del dibujo (px)
var shadow_size := -1.0               # tamaño forzado de la sombra (el aviso de la caída)
var charge := 0.0                     # 0..1 mientras prepara el ataque
var _hit_flash := 0.0
var home := Vector2.ZERO

var _states: Dictionary = {}
var _state: GuardianState
var _material := ShaderMaterial.new()

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var shadow: Sprite2D = $Sombra
@onready var eyes: PointLight2D = $Ojos
@onready var body_shape: CollisionShape2D = $Colision


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("guardians")
	set_collision_mask_value(4, true)    # la barrera del abismo (Sala 5) solo los detiene a ellos
	_material.shader = STONE_SHADER
	sprite.material = _material
	sprite.modulate = Color.WHITE
	hp = max_hp
	home = position
	attack = _make_attack()
	sprite.scale = Vector2.ONE * body_scale
	shadow.scale = Vector2.ONE * body_scale
	radius = 6.0 * body_scale
	_states = {
		"dormant": DormantState.new(self),
		"waking": WakingState.new(self),
		"dropping": DroppingState.new(self),
		"chase": ChaseState.new(self),
		"windup": WindupState.new(self),
		"strike": StrikeState.new(self),
		"stagger": StaggerState.new(self),
		"dying": DyingState.new(self),
	}
	change("dormant" if dormant else "chase")


## Estrategia de ataque de este tipo de guardián (Strategy): el caballero golpea y el
## hechicero lanza orbes.
func _make_attack() -> GuardianAttack:
	return OrbShot.new() if attack_kind == "orbe" else MeleeStrike.new()


func is_ranged() -> bool:
	return attack_kind == "orbe"


func setup(p_bus: EventBus, p_kit: TileKit, p_settings: Dictionary) -> void:
	bus = p_bus
	kit = p_kit
	settings = p_settings


func change(next: String) -> void:
	if _state:
		_state.exit()
	_state = _states[next]
	state_name = next
	_state.enter()


func _physics_process(delta: float) -> void:
	if _state == null:
		return
	cooldown = maxf(0.0, cooldown - delta)
	_hit_flash = maxf(0.0, _hit_flash - delta)
	var next := _state.physics(delta)
	if next != "":
		change(next)
	_update_visual()


func _update_visual() -> void:
	var jitter := Vector2(randf_range(-shake, shake), 0.0) if shake > 0.0 else Vector2.ZERO
	sprite.position = Vector2(0, -8 * body_scale - lift) + jitter
	shadow.scale = Vector2.ONE * body_scale * (shadow_size if shadow_size > 0.0 else clampf(1.0 - lift / 160.0, 0.25, 1.0))
	_material.set_shader_parameter("stone", stone)
	_material.set_shader_parameter("flash", maxf(glow, _hit_flash / 0.15))
	eyes.position = Vector2(0, -11 * body_scale - lift)
	var anim := "%s_%s" % [_state.animation(), dir_name()]
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.speed_scale = speed_scale
	if _state.animation() == "idle":
		sprite.stop()
		sprite.frame = 0
	queue_redraw()


## El aro del tipo bajo los pies, el orbe que prepara el hechicero y las grietas de la
## estatua al despertar.
func _draw() -> void:
	if is_active() and state_name != "dropping" and state_name != "waking":
		var pts := PackedVector2Array()
		for i in 21:
			pts.append(Vector2.from_angle(i * TAU / 20.0) * Vector2(8.0, 3.5) * body_scale)
		draw_colored_polygon(pts, Color(ring_color, 0.22))
		draw_polyline(pts, Color(ring_color, 0.85), 1.0)
	if is_ranged() and state_name == "windup":
		var hand := Vector2(facing.x * 6.0, -9.0 * body_scale + facing.y * 3.0)
		draw_circle(hand, 1.0 + 3.0 * charge, Color(ring_color, 0.5))
		draw_circle(hand, 0.5 + 1.5 * charge, Color(1, 1, 1, 0.9))
	if cracks <= 0.0:
		return
	var o := sprite.position
	var lines := [
		[Vector2(-1, -6), Vector2(1, -2), Vector2(-1, 1), Vector2(1, 4)],
		[Vector2(-5, -1), Vector2(-3, 1), Vector2(-4, 4)],
		[Vector2(4, -4), Vector2(2, -1), Vector2(4, 2), Vector2(3, 6)],
		[Vector2(-2, 3), Vector2(1, 5), Vector2(-1, 7)],
	]
	var shown := int(ceil(cracks * lines.size()))
	for i in mini(shown, lines.size()):
		var pts := PackedVector2Array()
		for p in lines[i]:
			pts.append(o + p)
		draw_polyline(pts, Color(0.08, 0.09, 0.1, 0.9), 1.0)


func dir_name() -> String:
	if absf(facing.x) > absf(facing.y):
		return "right" if facing.x > 0 else "left"
	return "down" if facing.y > 0 else "up"


# ------------------------------------------------------------------ órdenes del director

## La estatua despierta (alarma).
func wake() -> void:
	if state_name == "dormant":
		change("waking")


## Cae del techo en "at" (la sombra avisa antes).
func drop(at: Vector2) -> void:
	from_ceiling = true
	global_position = at
	change("dropping")


## Vuelve a ser una estatua quieta sobre su pedestal (al reaparecer Tala tras caer vencida).
func restore() -> void:
	hp = max_hp
	position = home
	velocity = Vector2.ZERO
	visible = true
	body_shape.set_deferred("disabled", false)
	change("dormant")


## Se deshace en números sin pelear (la sala quedó resuelta).
func dissolve() -> void:
	if is_active():
		change("dying")


## Despierto (o despertando o cayendo): cuenta como guardián de la ola.
func is_active() -> bool:
	return state_name != "dormant" and state_name != "dying" and visible


func can_be_hit() -> bool:
	return _state != null and _state.hittable()


func take_hit(amount: int, direction: Vector2) -> void:
	hp -= amount
	if bus:
		bus.publish(GameEvents.GUARDIAN_HIT)
	if hp <= 0:
		change("dying")
	elif staggers:
		(_states.stagger as StaggerState).push = direction
		change("stagger")
	else:
		_hit_flash = 0.15
		velocity = direction * 60.0


## Se destruye en su propio ataque (el rúnico al explotar).
func blow_up() -> void:
	if state_name != "dying":
		change("dying")


## Aviso de los estados para los tipos que se ven distinto (los redefine el rúnico).
func on_windup() -> void:
	pass


func on_landed() -> void:
	pass


# ------------------------------------------------------------------ formación

## A dónde ir para atacar en formación (los de cuerpo a cuerpo):
## - lejos de Tala, directo hacia ella;
## - si Tala se acerca a un compañero de distancia, el caballero más cercano a él se pone en
##   medio para cubrirlo;
## - cerca, cada uno toma un lugar distinto alrededor de Tala (la rodean, no hacen fila).
##   Para llegar a su lugar rodea a Tala por el borde (no la atraviesa).
func formation_target() -> Vector2:
	var p := player().global_position
	if global_position.distance_to(p) > 72.0:
		return p
	var ward := _ward_in_danger(p)
	if ward and _closest_melee_to(ward.global_position) == self:
		return p.lerp(ward.global_position, 0.45)
	var slot := formation_slot()
	if is_nan(slot):
		return p
	var now := (global_position - p).angle()
	var gap := angle_difference(now, slot)
	if absf(gap) > 0.5:
		slot = now + signf(gap) * 0.6
	return p + Vector2.from_angle(slot) * (reach + 3.0)


## El ángulo (alrededor de Tala) que le toca a este caballero, o NAN si no hay formación
## (está solo o lejos). Se reparten en orden, así nadie cruza por delante de otro.
func formation_slot() -> float:
	var p := player().global_position
	var melee: Array = get_tree().get_nodes_in_group("guardians").filter(func(g): return g.is_active() and not g.is_ranged() and g.global_position.distance_to(p) < 96.0)
	if melee.size() < 2 or not self in melee:
		return NAN
	melee.sort_custom(func(a, b): return (a.global_position - p).angle() < (b.global_position - p).angle())
	var base: float = (melee[0].global_position - p).angle()
	return base + melee.find(self) * TAU / melee.size()


## ¿Ya está en su lugar de la formación (o no hay formación)? Solo entonces golpea.
func in_formation() -> bool:
	var slot := formation_slot()
	return is_nan(slot) or absf(angle_difference((global_position - player().global_position).angle(), slot)) < 0.7


## Un compañero de distancia al que Tala se está acercando.
func _ward_in_danger(p: Vector2) -> Guardian:
	for g in get_tree().get_nodes_in_group("guardians"):
		if g != self and g.is_active() and g.is_ranged() and g.global_position.distance_to(p) < 64.0:
			return g
	return null


func _closest_melee_to(at: Vector2) -> Guardian:
	var best: Guardian = null
	for g in get_tree().get_nodes_in_group("guardians"):
		if g.is_active() and not g.is_ranged() and (best == null or g.global_position.distance_to(at) < best.global_position.distance_to(at)):
			best = g
	return best


## ¿Hay una línea libre (sin muros) hasta Tala? Los de distancia solo disparan así.
func clear_shot(from := Vector2.INF) -> bool:
	var p := player()
	if p == null:
		return false
	var origin := global_position if from == Vector2.INF else from
	var query := PhysicsRayQueryParameters2D.create(origin + Vector2(0, -6), p.global_position + Vector2(0, -6))
	query.exclude = [get_rid(), p.get_rid()]
	query.collision_mask = 1
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or not (hit.collider is StaticBody2D or hit.collider is TileMapLayer)


## El hechicero atrapado sin tiro se teletransporta (con humo) a un punto de la sala desde el
## que ve a Tala, ni muy cerca ni muy lejos. Devuelve false si no encontró ninguno.
func blink() -> bool:
	var p := player().global_position
	var spots: Array = get_tree().get_nodes_in_group("guardian_spots").map(func(m): return m.global_position)
	spots.shuffle()
	for at: Vector2 in spots:
		var d := at.distance_to(p)
		if d > 55.0 and d < shot_range and clear_shot(at):
			burst(Vector2(0, -6), "Smoke", 10, 0.8, Vector2(0, -20))
			global_position = at
			velocity = Vector2.ZERO
			burst(Vector2(0, -6), "Smoke", 10, 0.8, Vector2(0, -20))
			return true
	return false


# ------------------------------------------------------------------ ayudas para los estados

func player() -> PlayerController:
	return get_tree().get_first_node_in_group("player")


func to_player() -> Vector2:
	var p := player()
	return p.global_position - global_position if p else Vector2.ZERO


## El ritmo de la ola: con más alarma todo pasa un poco más rápido (con tope).
func pace() -> float:
	return 1.0 + (speed_scale - 1.0) * 0.6


func setting(key: String, fallback):
	return settings.get(key, fallback)


## Un puñado de partículas del pack que se borra solo al terminar.
func burst(at: Vector2, fx: String, amount: int, lifetime: float, gravity := Vector2(0, 60)) -> CPUParticles2D:
	if kit == null:
		return null
	var p := kit.particles(get_parent(), position + at, fx, amount, lifetime)
	p.gravity = gravity
	p.z_index = 4
	if fx == "RockGray":
		p.scale_amount_min = 0.45
		p.scale_amount_max = 0.7
	p.finished.connect(p.queue_free)
	p.emitting = true
	return p


## Se aleja un poco de los otros guardianes para no amontonarse.
func separation() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("guardians"):
		if other == self or not other.is_active():
			continue
		var away: Vector2 = global_position - other.global_position
		if away.length() < 14.0 and away.length() > 0.01:
			push += away.normalized() * (14.0 - away.length()) * 4.0
	return push
