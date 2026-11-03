## Guardián de la tumba (caballero y hechicero).
## Usa estados (State) y su forma de atacar es una estrategia (Strategy).
class_name Guardian
extends CharacterBody2D

signal defeated(guardian: Guardian)

const STONE_SHADER := preload("res://assets/efectos/piedra.gdshader")

@export var dormant := false
@export var kind := "caballero"
## "golpe" o "orbe".
@export_enum("golpe", "orbe") var attack_kind := "golpe"
@export var ring_color := Color(1.0, 0.78, 0.25)
@export var body_scale := 1.0
## Ataca de lejos.
@export var keep_distance := 80.0
@export var shot_range := 125.0
@export var max_hp := 3
@export var damage := 1    # mitades de corazón
@export var speed := 38.0
@export var reach := 14.0
@export var pedestal_height := 7.0
## Un golpe de garrote le cancela el ataque.
@export var staggers := true

var radius := 6.0
var hp := 3
var speed_scale := 1.0
var facing := Vector2.DOWN
var attack: GuardianAttack
var bus: EventBus
var kit: TileKit
var settings: Dictionary = {}         # sección "combat" de config.json
var from_ceiling := false    # cayó del techo
var state_name := ""
var lift := 0.0
var cooldown := 0.0
var cracks := 0.0
var glow := 0.0
var stone := 0.0    # 1 = piedra gris
var shake := 0.0
var shadow_size := -1.0
var charge := 0.0
var _hit_flash := 0.0
var home := Vector2.ZERO
## En la copia del espectador: no piensa, solo se dibuja como dice el jugador.
var puppet := false

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
	set_collision_mask_value(4, true)    # la barrera del abismo solo detiene a los guardianes
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


## El caballero golpea y el hechicero lanza orbes.
func _make_attack() -> GuardianAttack:
	return OrbShot.new() if attack_kind == "orbe" else MeleeStrike.new()


func is_ranged() -> bool:
	return attack_kind == "orbe"


func setup(p_bus: EventBus, p_kit: TileKit, p_settings: Dictionary) -> void:
	bus = p_bus
	kit = p_kit
	settings = p_settings


func change(next: String) -> void:
	if puppet and _state != null:
		return
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
	if puppet:
		_state.t += delta
		_update_visual()
		return
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


# ------------------------------------------------------------------ espectador (ver WorldSync)

## Lo que el espectador necesita para dibujarlo igual.
func net_pack() -> Dictionary:
	return {
		"k": kind,
		"x": roundi(global_position.x),
		"y": roundi(global_position.y),
		"s": state_name,
		"fx": snappedf(facing.x, 0.01),
		"fy": snappedf(facing.y, 0.01),
		"l": snappedf(lift, 0.1),
		"st": snappedf(stone, 0.01),
		"cr": snappedf(cracks, 0.01),
		"gl": snappedf(glow, 0.01),
		"ch": snappedf(charge, 0.01),
		"sh": snappedf(shake, 0.1),
		"ss": snappedf(shadow_size, 0.01),
		"sa": snappedf(shadow.modulate.a, 0.01),
		"e": snappedf(eyes.energy, 0.01),
		"v": visible,
		"sv": sprite.visible,
		"hf": _hit_flash > 0.0,
	}


## Títere: entre los estados a y b del jugador (w: cuánto de b).
func net_apply(a: Dictionary, b: Dictionary, w: float) -> void:
	var s := a if w < 0.5 else b
	var pa := Vector2(float(a.get("x", 0)), float(a.get("y", 0)))
	var pb := Vector2(float(b.get("x", 0)), float(b.get("y", 0)))
	global_position = pa.lerp(pb, w) if pa.distance_to(pb) < 80.0 else (pa if w < 0.5 else pb)
	var next := String(s.get("s", state_name))
	if next != state_name and _states.has(next):
		_puppet_switch(next)
	facing = Vector2(float(s.get("fx", 0)), float(s.get("fy", 1)))
	lift = lerpf(float(a.get("l", 0)), float(b.get("l", 0)), w)
	stone = float(s.get("st", 0))
	cracks = float(s.get("cr", 0))
	glow = float(s.get("gl", 0))
	charge = float(s.get("ch", 0))
	shake = float(s.get("sh", 0))
	shadow_size = float(s.get("ss", -1))
	shadow.modulate.a = float(s.get("sa", 0.75))
	eyes.energy = float(s.get("e", 0))
	visible = bool(s.get("v", true))
	sprite.visible = bool(s.get("sv", true))
	if bool(s.get("hf", false)):
		_hit_flash = 0.15
	var pedestal := get_parent() as Pedestal
	if pedestal:
		pedestal.rubble = state_name != "dormant"


## Cambia de estado sin su lógica (ni señales): solo los efectos que se ven.
func _puppet_switch(next: String) -> void:
	var prev := state_name
	_state = _states[next]
	_state.t = 0.0
	state_name = next
	if next == "dying":
		_puppet_die(prev)
	elif prev == "dropping":
		burst(Vector2(0, -2), "Smoke", 10, 0.9, Vector2(0, -10))
		burst(Vector2(0, -2), "RockGray", 8, 0.6)
		on_landed()
	elif next == "waking":
		burst(Vector2(0, -14), "RockGray", 6, 0.7)


func _puppet_die(prev: String) -> void:
	if self is RunicGuardian and prev in ["windup", "strike"]:
		(self as RunicGuardian).explosion_fx()
	var numbers := NumberBurst.new()
	numbers.position = position + Vector2(0, -6)
	get_parent().add_child(numbers)
	burst(Vector2(0, -6), "Smoke", 8, 0.8, Vector2(0, -20))
	visible = false


## Títere que ya no está en la sala del jugador.
func net_vanish() -> void:
	if visible and state_name != "dying":
		_puppet_die(state_name)
	queue_free()


## Estatua que volvió a dormir sobre su pedestal.
func net_restore() -> void:
	position = home
	visible = true
	sprite.visible = true
	_state = _states.dormant
	state_name = "dormant"
	_state.enter()
	var pedestal := get_parent() as Pedestal
	if pedestal:
		pedestal.rubble = false


# ------------------------------------------------------------------ órdenes del director

func wake() -> void:
	if state_name == "dormant":
		change("waking")


## Cae del techo en at.
func drop(at: Vector2) -> void:
	from_ceiling = true
	global_position = at
	change("dropping")


## Vuelve a su pedestal como estatua.
func restore() -> void:
	hp = max_hp
	position = home
	velocity = Vector2.ZERO
	visible = true
	body_shape.set_deferred("disabled", false)
	change("dormant")


## Desaparece sin pelear (la sala ya se resolvió).
func dissolve() -> void:
	if is_active():
		change("dying")


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


func blow_up() -> void:
	if state_name != "dying":
		change("dying")


func on_windup() -> void:
	pass


func on_landed() -> void:
	pass


# ------------------------------------------------------------------ formación

## A dónde ir para atacar: los caballeros rodean a Tala
## y cubren al hechicero si ella se le acerca.
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


## Ángulo alrededor de Tala que le toca a este caballero, o NAN.
func formation_slot() -> float:
	var p := player().global_position
	var melee: Array = get_tree().get_nodes_in_group("guardians").filter(func(g): return g.is_active() and not g.is_ranged() and g.global_position.distance_to(p) < 96.0)
	if melee.size() < 2 or not self in melee:
		return NAN
	melee.sort_custom(func(a, b): return (a.global_position - p).angle() < (b.global_position - p).angle())
	var base: float = (melee[0].global_position - p).angle()
	return base + melee.find(self) * TAU / melee.size()


func in_formation() -> bool:
	var slot := formation_slot()
	return is_nan(slot) or absf(angle_difference((global_position - player().global_position).angle(), slot)) < 0.7


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


## true si no hay muros entre él y Tala.
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


## El hechicero sin tiro se teletransporta a otro punto. false si no encontró.
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


## Con más alarma son más rápidos.
func pace() -> float:
	return 1.0 + (speed_scale - 1.0) * 0.6


func setting(key: String, fallback):
	return settings.get(key, fallback)


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


## Se separa de los otros para no amontonarse.
func separation() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("guardians"):
		if other == self or not other.is_active():
			continue
		var away: Vector2 = global_position - other.global_position
		if away.length() < 14.0 and away.length() > 0.01:
			push += away.normalized() * (14.0 - away.length()) * 4.0
	return push
