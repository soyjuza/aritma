## El jefe final: el Guardián del Cero (escena: scenes/enemigos/jefe_cero.tscn), un tengu
## rojo y alado que sella el núcleo de la Sala 5. Aparece en la antesala cuando Tala toca el
## núcleo, y el sello no se rompe hasta vencerlo.
## Pelea en 4 fases (la vida se reparte en partes iguales):
## - Persigue a Tala despacio y la ataca de dos maneras, que se avisan antes:
##   · Ráfaga: abre las alas y lanza un abanico de orbes rojos (3, 5, 6 y 7 según la fase). Se
##     esquivan corriendo y el garrote los deshace.
##   · Pisotón: salta, un círculo rojo marca dónde cae y al caer quita un corazón a quien esté
##     dentro sin estar saltando. Después queda cansado un momento: es el mejor momento para
##     pegarle.
## - Al cambiar de fase se cubre con un escudo y pone a prueba a Tala con un problema (la sala
##   abre QuizState). Si acierta, el escudo cae; si falla o se acaba el tiempo, llama a una ola
##   de guardianes (summon) y el escudo cae cuando no queda ninguno.
## Contexto del patrón State en versión simple: cada estado es una función (_state_...) y
## change() cambia de una a otra.
class_name ZeroBoss
extends CharacterBody2D

signal defeated
signal shielded

const ORB := preload("res://scenes/enemigos/orbe.tscn")
const RED := Color("ff3b2f")
const CYAN := Color("3fe0ff")
const SHEETS := {
	"idle": [preload("res://assets/pack/actors/TenguRed/Idle.png"), 6, 8.0],
	"walk": [preload("res://assets/pack/actors/TenguRed/Walk.png"), 10, 12.0],
	"attack": [preload("res://assets/pack/actors/TenguRed/Attack.png"), 15, 14.0],
	"hit": [preload("res://assets/pack/actors/TenguRed/Hit.png"), 8, 16.0],
	"appear": [preload("res://assets/pack/actors/TenguRed/Trans.png"), 11, 7.0],
}

@export var max_hp := 16
@export var speed := 30.0
@export var orbs_per_phase: Array[int] = [3, 5, 6, 7]
## Nivel de alarma de la ola si falla el problema de cada fase (con "waves" de config.json:
## nivel 4 = 4 guardianes, 5 = 5, 6 = 6).
@export var waves_on_fail: Array[int] = [0, 4, 5, 6]
@export var slam_radius := 42.0
@export var slam_damage := 2                          # mitades de corazón
@export var touch_damage := 1
@export var wake_distance := 150.0                    # más lejos que esto, espera en su lugar

var radius := 11.0
var hp := 16
var phase := 0
var awaiting_answer := false   # con el escudo puesto, esperando la respuesta del problema
var state := "hidden"
var alarm: AlarmDirector
var bus: EventBus
var home := Vector2.ZERO
var hold_while: Callable     # mientras devuelva true se queda quieto (Tala lee un diálogo)
var arena := Rect2()         # dónde puede caer el pisotón (la antesala, en coordenadas globales)

var _t := 0.0                # tiempo en el estado actual
var _next_attack := 1.6
var _slam_at := Vector2.ZERO
var _lift := 0.0
var _flash := 0.0
var _shield := 0.0           # 0..1: el escudo se ve
var _wave_ring := -1.0       # radio de la onda del pisotón (-1: no hay)
var _anim := "idle"
var _anim_t := 0.0
var _bar: Control

@onready var sprite: Sprite2D = $Sprite
@onready var shadow: Sprite2D = $Sombra
@onready var body_shape: CollisionShape2D = $Colision
@onready var light: PointLight2D = $Luz


func _ready() -> void:
	add_to_group("boss")
	set_collision_mask_value(4, true)    # tampoco cruza el abismo
	home = position
	hp = max_hp
	_bar = BossBar.new(self)
	var layer := CanvasLayer.new()
	layer.layer = 4
	layer.add_child(_bar)
	add_child(layer)
	change("hidden")


func setup(p_bus: EventBus, p_alarm: AlarmDirector) -> void:
	bus = p_bus
	alarm = p_alarm


# ------------------------------------------------------------------ órdenes de la sala

## Sale del abismo (Tala tocó el núcleo sellado).
func appear() -> void:
	if state == "hidden":
		change("appear")


## Tala cayó vencida: vuelve a su lugar, con la vida del comienzo de la fase en la que iba.
func reset_for_retry() -> void:
	if state == "hidden" or state == "dying":
		return
	hp = max_hp - phase * phase_hp()
	position = home
	velocity = Vector2.ZERO
	change("wait")


## La respuesta al problema del escudo: si falló, llama a su ola de guardianes (más grande en
## cada fase); si acertó, el escudo cae sin pelear.
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
	return is_awake() and state != "appear" and state != "shield"


func take_hit(amount: int, direction: Vector2) -> void:
	hp -= amount
	_flash = 0.15
	velocity = direction * 50.0
	if bus:
		bus.publish(GameEvents.GUARDIAN_HIT)
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


# ------------------------------------------------------------------ estados

func change(next: String) -> void:
	state = next
	_t = 0.0
	match next:
		"hidden":
			visible = false
			body_shape.set_deferred("disabled", true)
			_bar.visible = false
		"appear":
			visible = true
			position = home
			body_shape.set_deferred("disabled", false)
			_bar.visible = true
			_play("appear")
			if bus:
				bus.publish(GameEvents.BOSS_APPEARED)
		"wait", "chase":
			_play("idle")
		"volley":
			_play("attack")
			if bus:
				bus.publish(GameEvents.GUARDIAN_CHARGING)
		"slam":
			_slam_at = _player().global_position if _player() else global_position
			if arena.has_area():
				_slam_at = _slam_at.clamp(arena.position, arena.end)
			_play("idle")
			if bus:
				bus.publish(GameEvents.GUARDIAN_CHARGING)
		"tired":
			_play("hit")
		"shield":
			_play("idle")
			awaiting_answer = true
			if bus:
				bus.publish(GameEvents.BOSS_SHIELD)
			shielded.emit()
		"dying":
			_play("hit")
			body_shape.set_deferred("disabled", true)
			if bus:
				bus.publish(GameEvents.BOSS_DEFEATED)


func _physics_process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta)
	_shield = move_toward(_shield, 1.0 if state == "shield" else 0.0, delta * 3.0)
	if _wave_ring >= 0.0:
		_wave_ring += delta * 160.0
		if _wave_ring > slam_radius * 1.4:
			_wave_ring = -1.0
	if hold_while.is_valid() and hold_while.call() and state != "appear":
		_animate(delta)
		queue_redraw()
		return
	match state:
		"appear":
			_lift = 0.0
			if _t >= 11.0 / 7.0 + 0.4:
				change("chase")
		"wait":
			_state_wait(delta)
		"chase":
			_state_chase(delta)
		"volley":
			_state_volley(delta)
		"slam":
			_state_slam(delta)
		"tired":
			velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
			move_and_slide()
			if _t >= 1.8:
				change("chase")
		"shield":
			velocity = (home - position) * 2.0
			move_and_slide()
			if _t > 1.0 and not awaiting_answer and (alarm == null or not alarm.fighting()):
				change("chase")
		"dying":
			modulate.a = 1.0 - clampf((_t - 1.0) / 1.0, 0.0, 1.0)
			if randf() < 0.15:
				var burst := NumberBurst.new()
				burst.count = 3
				burst.tint = RED if randf() < 0.5 else CYAN
				burst.position = position + Vector2(randf_range(-14, 14), randf_range(-30, -6))
				get_parent().add_child(burst)
			if _t >= 2.0:
				change("hidden")
				modulate.a = 1.0
				defeated.emit()
	_animate(delta)
	queue_redraw()


## Espera en su lugar hasta que Tala vuelve a la antesala.
func _state_wait(delta: float) -> void:
	velocity = (home - position) * 2.0
	move_and_slide()
	var p := _player()
	if p and _t > 1.5 and p.global_position.distance_to(position) < wake_distance:
		change("chase")


## Se acerca a Tala sin pegarse a ella; cuando le toca, ataca.
func _state_chase(delta: float) -> void:
	var p := _player()
	if p == null:
		return
	var to := p.global_position - global_position
	var want := to.normalized() * speed * (1.0 + 0.2 * phase) if to.length() > 34.0 else Vector2.ZERO
	velocity = velocity.move_toward(want, 300.0 * delta)
	move_and_slide()
	_play("walk" if velocity.length() > 5.0 else "idle")
	sprite.flip_h = to.x < 0.0
	if to.length() < radius + 6.0 and not p.airborne:
		p.hurt(touch_damage, global_position)
	_next_attack -= delta
	if _next_attack <= 0.0:
		_next_attack = 2.2 - 0.4 * phase
		change("slam" if to.length() < 70.0 else "volley")


## Abre las alas (aviso) y lanza un abanico de orbes hacia Tala.
func _state_volley(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	move_and_slide()
	if _t >= 0.75 and _t - delta < 0.75:
		_fire_fan(orbs_per_phase[phase])
	if _t >= 15.0 / 14.0:
		change("chase")


func _fire_fan(count: int) -> void:
	var p := _player()
	if p == null:
		return
	var from := global_position + Vector2(0, -16)
	var aim := (p.global_position + Vector2(0, -4) - from).angle()
	for i in count:
		var orb: RuneOrb = ORB.instantiate()
		var angle := aim + (i - (count - 1) / 2.0) * 0.28
		orb.position = get_parent().to_local(from)
		orb.velocity = Vector2.from_angle(angle) * 80.0
		orb.color = RED
		orb.damage = 1
		orb.life = 3.2
		get_parent().add_child(orb)
	if bus:
		bus.publish(GameEvents.ORB_FIRED)


## Salta, cae donde estaba Tala y la onda daña a quien esté dentro del círculo sin saltar.
func _state_slam(delta: float) -> void:
	var rise := 0.9
	var land := 1.3
	if _t < rise:
		_lift = 40.0 * sin(_t / rise * PI * 0.5)
		global_position = global_position.lerp(_slam_at, delta * 2.5)
	elif _t < land:
		_lift = 40.0 * (1.0 - (_t - rise) / (land - rise))
		global_position = global_position.lerp(_slam_at, delta * 6.0)
	elif _lift > 0.0:
		_lift = 0.0
		_wave_ring = 0.0
		if bus:
			bus.publish(GameEvents.BOSS_SLAM)
		var p := _player()
		if p and not p.airborne and p.global_position.distance_to(global_position) <= slam_radius:
			p.hurt(slam_damage, global_position)
		change("tired")


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
	sprite.position = Vector2(0, -26 - _lift)
	sprite.modulate = Color(3, 3, 3) if _flash > 0.0 else Color.WHITE
	shadow.scale = Vector2.ONE * 2.2 * clampf(1.0 - _lift / 80.0, 0.5, 1.0)
	light.energy = 0.8 + 0.4 * sin(_t * 4.0) + 0.6 * _shield


func _draw() -> void:
	if not visible:
		return
	# Aviso del pisotón: círculo rojo donde va a caer (se llena mientras baja)
	if state == "slam":
		var at := _slam_at - global_position
		var k := clampf(_t / 1.3, 0.0, 1.0)
		draw_circle(at, slam_radius, Color(RED, 0.10 + 0.15 * k))
		draw_arc(at, slam_radius, 0, TAU, 40, Color(RED, 0.9), 1.0)
		draw_arc(at, slam_radius * k, 0, TAU, 40, Color(RED, 0.6), 1.0)
	if _wave_ring >= 0.0:
		draw_arc(Vector2.ZERO, _wave_ring, 0, TAU, 40, Color(1, 0.8, 0.6, 1.0 - _wave_ring / (slam_radius * 1.4)), 2.0)
	# Escudo de fase
	if _shield > 0.0:
		var c := Vector2(0, -24)
		draw_circle(c, 24.0, Color(CYAN, 0.12 * _shield))
		draw_arc(c, 24.0, 0, TAU, 32, Color(CYAN, 0.8 * _shield), 1.0)
		for i in 6:
			var a := _t * 1.5 + i * TAU / 6.0
			draw_circle(c + Vector2.from_angle(a) * 24.0, 1.5, Color(CYAN, _shield))
	# Cansado: estrellas sobre la cabeza
	if state == "tired":
		for i in 3:
			var a := _t * 5.0 + i * TAU / 3.0
			draw_circle(Vector2(0, -50) + Vector2(cos(a) * 9.0, sin(a) * 3.0), 1.2, Color("ffc857"))


func _player() -> PlayerController:
	return get_tree().get_first_node_in_group("player")


## La barra de vida del jefe, abajo al centro de la pantalla, con su nombre.
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
		var title := "EL GUARDIÁN DEL CERO"
		var tw := _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string_outline(_font, Vector2((size.x - tw) / 2.0, bar.position.y - 8.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color("101418"))
		draw_string(_font, Vector2((size.x - tw) / 2.0, bar.position.y - 8.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe0d8"))
