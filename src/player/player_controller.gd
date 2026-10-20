## Tala: movimiento con estados (State), golpes y vida.
class_name PlayerController
extends CharacterBody2D

const REACH := 14.0

var walk_speed := 72.0
var run_speed := 124.0
var accel := 900.0
var stamina_max := 3.5
var stamina_regen := 0.9
var jump_time := 0.42
var jump_height := 10.0
var jump_cooldown := 0.15

var facing := Vector2.DOWN
var stamina := 3.5
var controls_enabled := true
var airborne := false    # en el aire los fosos no la tumban
var falling := false
var hop_height := 0.0
var state_name := "idle"
var dead := false

# Combate (config.json, "combat")
var health: PlayerHealth
var combat: Dictionary = {}
var attack_time := 0.28
var attack_cooldown := 0.12
var attack_reach := 20.0
var attack_arc := deg_to_rad(75.0)
var invulnerable := 0.0

var _bus: EventBus
var _states: Dictionary = {}
var _state: MoveState
var _run_locked := false
var _jump_wait := 0.0
var _attack_wait := 0.0
var _hurt_flash := 0.0

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _shadow: Sprite2D = $Sombra
@onready var _lamp: PointLight2D = $Lampara
@onready var _club: Sprite2D = $Garrote


func _ready() -> void:
	add_to_group("player")


## Recibe el bus y los valores de movimiento de config.json.
func setup(bus: EventBus, movement: Dictionary) -> void:
	_bus = bus
	for key in movement.keys():
		if key in self:
			set(key, movement[key])
	stamina = stamina_max
	_states = {
		"idle": IdleState.new(self),
		"walk": WalkState.new(self),
		"run": RunState.new(self),
		"jump": JumpState.new(self),
		"fall": FallState.new(self),
		"attack": AttackState.new(self),
	}
	_state = _states.idle


func _physics_process(delta: float) -> void:
	if _state == null:
		return
	_jump_wait = maxf(0.0, _jump_wait - delta)
	_attack_wait = maxf(0.0, _attack_wait - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	if dead:
		velocity = velocity.move_toward(Vector2.ZERO, accel * delta)
		move_and_slide()
		_update_sprite()
		return
	if _state.regenerates_stamina():
		stamina = minf(stamina_max, stamina + stamina_regen * delta)
		if stamina > stamina_max * 0.3:
			_run_locked = false
	var next := _state.physics(delta)
	if next != "" and _states.has(next):
		change(next)
	_update_sprite()


func change(next: String) -> void:
	_state.exit()
	var previous := state_name
	_state = _states[next]
	state_name = next
	_state.enter(previous)
	_bus.publish(GameEvents.MOVE_STATE_CHANGED, {"state": next})


func _update_sprite() -> void:
	_sprite.position = Vector2(0, -8 - hop_height)
	_shadow.scale = Vector2.ONE * (1.0 - hop_height / (jump_height * 3.0))
	# Después de un golpe parpadea
	var tint := Color(1.0, 0.45, 0.4) if _hurt_flash > 0.0 else Color.WHITE
	_sprite.modulate = Color(tint, _sprite.modulate.a)
	_sprite.visible = dead or invulnerable <= 0.0 or fmod(invulnerable, 0.14) > 0.05
	if dead:
		if _sprite.animation != "dead":
			_sprite.play("dead")
		return
	var anim := "%s_%s" % [_state.animation(), _dir_name()]
	if _sprite.animation != anim:
		_sprite.play(anim)
	_sprite.speed_scale = _state.animation_speed()
	if _state.animation() == "idle":
		_sprite.stop()
		_sprite.frame = 0


func _dir_name() -> String:
	if absf(facing.x) > absf(facing.y):
		return "right" if facing.x > 0 else "left"
	return "down" if facing.y > 0 else "up"


# ------------------------------------------------------------------ ayudas para los estados

func input_vector() -> Vector2:
	if not controls_enabled or dead:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func has_move_input() -> bool:
	return input_vector().length() > 0.1


func wants_run() -> bool:
	return controls_enabled and not _run_locked and stamina > 0.05 and Input.is_action_pressed("run")


func wants_jump() -> bool:
	return controls_enabled and not dead and _jump_wait <= 0.0 and Input.is_action_just_pressed("jump")


func wants_attack() -> bool:
	return controls_enabled and not dead and _attack_wait <= 0.0 and Input.is_action_just_pressed("attack")


func move_toward_input(speed: float, delta: float) -> void:
	var dir := input_vector()
	if dir.length() > 0.1:
		facing = dir.normalized()
	velocity = velocity.move_toward(dir * speed, accel * delta)


func spend_stamina(delta: float) -> void:
	stamina = maxf(0.0, stamina - delta)
	if stamina <= 0.05:
		_run_locked = true


func jumped() -> void:
	_bus.publish(GameEvents.JUMP)


func landed() -> void:
	_jump_wait = jump_cooldown
	_bus.publish(GameEvents.LAND)


## Cae a un foso.
func fall() -> void:
	falling = true
	change("fall")
	var t := create_tween()
	t.tween_property(_sprite, "scale", Vector2.ONE * 0.2, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.55)
	t.parallel().tween_property(_shadow, "modulate:a", 0.0, 0.3)
	await t.finished


# ------------------------------------------------------------------ combate

func apply_combat(values: Dictionary) -> void:
	combat = values
	attack_time = float(values.get("attack_time", attack_time))
	attack_cooldown = float(values.get("attack_cooldown", attack_cooldown))
	attack_reach = float(values.get("attack_reach", attack_reach))
	attack_arc = deg_to_rad(float(values.get("attack_arc_deg", 75.0)))


func start_swing() -> void:
	_club.visible = true
	update_swing(0.0)
	var swing := GlyphSwing.new()
	swing.direction = facing
	swing.position = global_position + Vector2(0, -7)
	get_parent().add_child(swing)
	_bus.publish(GameEvents.PLAYER_ATTACK)


func update_swing(k: float) -> void:
	var angle := facing.angle() + lerpf(-1.2, 1.2, ease(k, 0.5))
	var dir := Vector2.from_angle(angle)
	_club.position = Vector2(0, -7) + dir * 5.0
	_club.rotation = angle + PI / 2.0
	var behind := facing.y < -0.5
	if behind != (_club.get_index() < _sprite.get_index()):
		move_child(_club, _sprite.get_index())


func end_swing() -> void:
	_club.visible = false
	_attack_wait = attack_cooldown


## Momento del impacto: golpea guardianes y orbes delante de ella.
func strike() -> void:
	for orb in get_tree().get_nodes_in_group("orbs"):
		var at: Vector2 = orb.global_position - (global_position + Vector2(0, -6))
		if at.length() <= attack_reach + 4.0 and absf(facing.angle_to(at)) <= attack_arc:
			orb.shatter()
	for guardian in get_tree().get_nodes_in_group("guardians") + get_tree().get_nodes_in_group("boss"):
		if not guardian.can_be_hit():
			continue
		var to: Vector2 = guardian.global_position - global_position
		if to.length() <= attack_reach + guardian.radius and absf(facing.angle_to(to)) <= attack_arc:
			guardian.take_hit(1, to.normalized() if to.length() > 0.1 else facing)


## Recibe un golpe. force: aunque esté parpadeando.
func hurt(amount: int, from: Vector2, force := false) -> void:
	if dead or falling or health == null or (invulnerable > 0.0 and not force):
		return
	var push := global_position - from
	velocity = (push.normalized() if push.length() > 0.1 else -facing) * float(combat.get("knockback", 170.0))
	_hurt_flash = 0.18
	if not health.damage(amount):
		invulnerable = float(combat.get("invulnerable_sec", 1.0))


## Sin corazones: queda en el suelo.
func die() -> void:
	dead = true
	invulnerable = 0.0
	_club.visible = false
	if _state.stops_on_death():
		change("idle")


func set_lamp(on: bool) -> void:
	_lamp.visible = on


func place(at: Vector2, face := Vector2.DOWN) -> void:
	global_position = at
	velocity = Vector2.ZERO
	facing = face
	falling = false
	dead = false
	invulnerable = 0.0
	_hurt_flash = 0.0
	airborne = false
	hop_height = 0.0
	_sprite.scale = Vector2.ONE
	_sprite.modulate = Color.WHITE
	_sprite.visible = true
	_club.visible = false
	_shadow.modulate.a = 0.75
	change("idle")


## Lo que tiene delante para usar con E, o null.
func focused_interactable() -> Interactable:
	var query := PhysicsPointQueryParameters2D.new()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = Interactable.LAYER
	var space := get_world_2d().direct_space_state
	for offset in [facing * REACH, facing * REACH * 0.5, Vector2.ZERO]:
		query.position = global_position + Vector2(0, -4) + offset
		for hit in space.intersect_point(query, 4):
			if hit.collider is Interactable:
				return hit.collider
	return null
