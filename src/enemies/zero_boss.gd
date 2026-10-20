## Jefe final: el Guardián del Cero.
## Tiene 4 fases; al perder cada una se cubre con un escudo y pone un problema.
## Usa estados (State), en src/enemies/boss_states/.
class_name ZeroBoss
extends CharacterBody2D

signal defeated
signal shielded
signal shield_down

const RED := Color("ff3b2f")
const CYAN := Color("3fe0ff")
const SHEETS := {
	"idle": [preload("res://assets/pack/actors/TenguRed/Idle.png"), 6, 8.0],
	"walk": [preload("res://assets/pack/actors/TenguRed/Walk.png"), 10, 12.0],
	"attack": [preload("res://assets/pack/actors/TenguRed/Attack.png"), 15, 14.0],
	"hit": [preload("res://assets/pack/actors/TenguRed/Hit.png"), 8, 16.0],
	"appear": [preload("res://assets/pack/actors/TenguRed/Trans.png"), 11, 7.0],
}

# Valores por defecto. setup() los cambia por los de config.json ("boss").
@export var max_hp := 16
@export var speed := 30.0
@export var speed_per_phase := 0.2
@export var accel := 300.0
@export var keep_distance := 34.0
@export var wake_distance := 150.0
@export var wake_delay := 1.5
@export var appear_pause := 0.4
@export var first_attack := 1.6
@export var attack_every := 2.2
@export var attack_every_step := 0.4
@export var slam_range := 70.0    # más cerca: pisotón; más lejos: ráfaga
@export var orbs_per_phase: Array[int] = [3, 5, 6, 7]
@export var orb_spread := 0.28
@export var orb_speed := 80.0
@export var orb_life := 3.2
@export var volley_fire_at := 0.75
@export var slam_radius := 42.0
@export var slam_damage := 2    # mitades de corazón
@export var slam_rise := 0.9
@export var slam_land := 1.3
@export var slam_height := 40.0
@export var ring_speed := 160.0
@export var tired_time := 1.8
@export var touch_damage := 1
@export var dying_time := 2.0
## Guardianes que llama si falla el problema de cada fase.
@export var waves_on_fail: Array[int] = [0, 4, 5, 6]

var radius := 11.0
var hp := 16
var phase := 0
var awaiting_answer := false
var state := "hidden"
var alarm: AlarmDirector
var bus: EventBus
var home := Vector2.ZERO
var hold_while: Callable    # si devuelve true se queda quieto
var arena := Rect2()
var next_attack := 1.6
var lift := 0.0
var wave_ring := -1.0    # -1: no hay onda
var bar: Control
var title := ""               # el nombre sobre la barra de vida (texts.json → "boss_name")

var _states: Dictionary = {}
var _state: BossState
var _clock := 0.0
var _flash := 0.0
var _shield := 0.0
var _anim := "idle"
var _anim_t := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var shadow: Sprite2D = $Sombra
@onready var body_shape: CollisionShape2D = $Colision
@onready var light: PointLight2D = $Luz


func _ready() -> void:
	add_to_group("boss")
	set_collision_mask_value(4, true)
	home = position
	hp = max_hp
	bar = BossBar.new(self)
	var layer := CanvasLayer.new()
	layer.layer = 4
	layer.add_child(bar)
	add_child(layer)
	_states = {
		"hidden": BossHiddenState.new(self),
		"appear": BossAppearState.new(self),
		"wait": BossWaitState.new(self),
		"chase": BossChaseState.new(self),
		"volley": BossVolleyState.new(self),
		"slam": BossSlamState.new(self),
		"tired": BossTiredState.new(self),
		"shield": BossShieldState.new(self),
		"dying": BossDyingState.new(self),
	}
	change("hidden")


## Recibe el bus, la alarma y los valores de config.json.
func setup(p_bus: EventBus, p_alarm: AlarmDirector, tuning: Dictionary = {}) -> void:
	bus = p_bus
	alarm = p_alarm
	for key in tuning.keys():
		if not key in self:
			continue
		var current = get(key)
		if current is Array:
			(current as Array).assign((tuning[key] as Array).map(func(v): return int(v)))
		elif current is int:
			set(key, int(tuning[key]))
		else:
			set(key, tuning[key])
	hp = max_hp
	next_attack = first_attack


func change(next: String) -> void:
	if _state:
		_state.exit()
	_state = _states[next]
	state = next
	_state.enter()


func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(0.0, _flash - delta)
	_shield = move_toward(_shield, 1.0 if state == "shield" else 0.0, delta * 3.0)
	if wave_ring >= 0.0:
		wave_ring += delta * ring_speed
		if wave_ring > slam_radius * 1.4:
			wave_ring = -1.0
	var paused: bool = hold_while.is_valid() and hold_while.call() and state != "appear"
	if not paused:
		var next := _state.physics(delta)
		if next != "":
			change(next)
		_play(_state.animation())
	_animate(delta)
	queue_redraw()


# ------------------------------------------------------------------ órdenes de la sala

func appear() -> void:
	if state == "hidden":
		change("appear")


## Si Tala muere, el jefe vuelve a la fase 1 con toda la vida.
func reset_for_retry() -> void:
	if state == "hidden" or state == "dying":
		return
	hp = max_hp
	phase = 0
	awaiting_answer = false
	wave_ring = -1.0
	position = home
	velocity = Vector2.ZERO
	change("wait")


## Si falló el problema, llama a sus guardianes.
func answered(right: bool) -> void:
	awaiting_answer = false
	if not right and alarm and waves_on_fail[phase] > 0:
		alarm.summon(waves_on_fail[phase])


func is_awake() -> bool:
	return state != "hidden" and state != "dying"


func phase_hp() -> int:
	return int(ceil(float(max_hp) / orbs_per_phase.size()))


# ------------------------------------------------------------------ golpes de Tala

func can_be_hit() -> bool:
	return _state != null and _state.hittable()


func take_hit(amount: int, direction: Vector2) -> void:
	hp -= amount
	_flash = 0.15
	velocity = direction * 50.0
	publish(GameEvents.GUARDIAN_HIT)
	var burst := NumberBurst.new()
	burst.count = 4
	burst.tint = RED
	burst.position = position + Vector2(0, -20)
	get_parent().add_child(burst)
	if hp <= 0:
		change("dying")
	elif hp <= max_hp - (phase + 1) * phase_hp():
		phase += 1
		change("shield")


# ------------------------------------------------------------------ ayudas para los estados

func publish(event: StringName) -> void:
	if bus:
		bus.publish(event)


func player() -> PlayerController:
	return get_tree().get_first_node_in_group("player")


func return_home() -> void:
	velocity = (home - position) * 2.0
	move_and_slide()


func brake(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, accel * delta)
	move_and_slide()


## Duración de una animación en segundos.
func anim_length(anim: String) -> float:
	return float(SHEETS[anim][1]) / SHEETS[anim][2]


# ------------------------------------------------------------------ dibujo

func _play(anim: String) -> void:
	if _anim == anim:
		return
	_anim = anim
	_anim_t = 0.0
	sprite.texture = SHEETS[anim][0]
	sprite.hframes = SHEETS[anim][1]
	sprite.frame = 0


func _animate(delta: float) -> void:
	_anim_t += delta
	var frames: int = SHEETS[_anim][1]
	var n := int(_anim_t * SHEETS[_anim][2])
	sprite.frame = mini(n, frames - 1) if _anim in ["appear", "attack"] else n % frames
	sprite.position = Vector2(0, -26 - lift)
	sprite.modulate = Color(3, 3, 3) if _flash > 0.0 else Color.WHITE
	shadow.scale = Vector2.ONE * 2.2 * clampf(1.0 - lift / 80.0, 0.5, 1.0)
	light.energy = 0.8 + 0.4 * sin(_clock * 4.0) + 0.6 * _shield


func _draw() -> void:
	if not visible:
		return
	_state.draw()
	if wave_ring >= 0.0:
		draw_arc(Vector2.ZERO, wave_ring, 0, TAU, 40, Color(1, 0.8, 0.6, 1.0 - wave_ring / (slam_radius * 1.4)), 2.0)
	if _shield > 0.0:
		var c := Vector2(0, -24)
		draw_circle(c, 24.0, Color(CYAN, 0.12 * _shield))
		draw_arc(c, 24.0, 0, TAU, 32, Color(CYAN, 0.8 * _shield), 1.0)
		for i in 6:
			var a := _clock * 1.5 + i * TAU / 6.0
			draw_circle(c + Vector2.from_angle(a) * 24.0, 1.5, Color(CYAN, _shield))


## Barra de vida del jefe.
class BossBar extends Control:
	var boss: ZeroBoss
	var _font: Font = load(UIKit.PIXEL_FONT)

	func _init(p_boss: ZeroBoss) -> void:
		boss = p_boss
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var w := minf(size.x * 0.5, 520.0)
		var bar := Rect2((size.x - w) / 2.0, size.y - 66.0, w, 12.0)
		draw_rect(bar.grow(3), Color("101418"))
		draw_rect(bar, Color("3a1418"))
		var k := clampf(float(boss.hp) / boss.max_hp, 0.0, 1.0)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), CYAN if boss.state == "shield" else RED)
		for i in range(1, boss.orbs_per_phase.size()):
			var x := bar.position.x + bar.size.x * (1.0 - float(i * boss.phase_hp()) / boss.max_hp)
			draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Color("101418"), 2.0)
		var title := boss.title
		var tw := _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string_outline(_font, Vector2((size.x - tw) / 2.0, bar.position.y - 8.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color("101418"))
		draw_string(_font, Vector2((size.x - tw) / 2.0, bar.position.y - 8.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe0d8"))
