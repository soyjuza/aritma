## Sala 6 — El Trono del Cero (escena: scenes/niveles/sala_6_trono.tscn). El jefe final.
## Sin máquina ni código: al entrar a la sala, el Guardián del Cero (ZeroBoss) despierta y hay
## que vencerlo. Al cambiar de fase se cubre con un escudo y pone un problema de repaso de las
## salas (QuizState, con BossQuiz). Si Tala falla o se le acaba el tiempo, el jefe llama una ola
## de guardianes (el Director de Alarma de la sala, con los puntos «Guardianes/Caidas»); si
## acierta, el escudo cae sin pelear. Vencerlo gana el juego.
## Al aparecer el jefe, Tala recupera corazones, y cada vez que cae el escudo aparece una
## poción (HeartPotion) que cura un corazón. Si Tala cae, la pelea empieza de nuevo.
class_name ThroneLevel
extends ChamberLevel

const POTION := preload("res://scenes/objetos/pocion.tscn")

## Dónde puede caer el pisotón del jefe (el piso de la sala, sin los muros).
@export var arena := Rect2(48, 56, 400, 250)

var _in_hall := false
var _framing := false       # la cámara muestra al jefe mientras se lee la presentación
var _rng := RandomNumberGenerator.new()

@onready var boss: ZeroBoss = $Actores/JefeCero


func wire() -> void:
	boss.setup(_game.bus, alarm)
	boss.hold_while = _game.dialog.is_open
	boss.arena = Rect2(to_global(arena.position), arena.size)
	boss.defeated.connect(_on_boss_defeated)
	boss.shielded.connect(_ask_question)
	boss.shield_down.connect(_drop_potion)
	_rng.randomize()
	alarm.cleared_key = "boss_shield_down"
	$Zonas/EntradaSala.crossed.connect(_on_hall_entered)


func _on_hall_entered() -> void:
	if _in_hall:
		return
	_in_hall = true
	objective_key = "objective_throne_boss"
	boss.appear()
	_game.health.heal(int(_game.combat("heal_on_boss", 4)))
	# La cámara muestra al jefe mientras aparece; mientras se lee, el jefe espera. Al cerrar el
	# diálogo, la cámara vuelve a Tala y empieza la pelea.
	_framing = true
	_game.rig.frame(boss.global_position + Vector2(0, 20), 1.0, 0.8)
	_game.dialog.say(data.get("intro", []))


## El escudo: un problema de repaso (el de la fase que empieza, según chambers.json "quiz").
func _ask_question() -> void:
	# Primero se ve el escudo; la prueba sale cuando Tala está jugando (no en otro reto)
	await get_tree().create_timer(0.8).timeout
	while not _game.machine.current is PlayState:
		await get_tree().process_frame
	var settings: Dictionary = data.get("quiz", {})
	var kinds: Array = settings.get("kinds", ["paridad", "multiplo", "despejar"])
	var kind := String(kinds[clampi(boss.phase - 1, 0, kinds.size() - 1)])
	_game.machine.change("quiz", {"quiz": BossQuiz.make(kind, _rng), "seconds": float(settings.get("seconds", 15)), "on_done": _on_answered})


func _on_answered(right: bool) -> void:
	boss.answered(right)
	_game.notify([_game.data.message("boss_quiz_right" if right else "boss_quiz_wrong")], 4.0)


func _physics_process(_delta: float) -> void:
	if _framing and not _game.dialog.is_open():
		_framing = false
		_game.follow_player()


## Una poción en un lugar al azar de la sala, en piso libre (no sobre una columna) y lejos del
## jefe y de Tala (hay que ir por ella).
func _drop_potion() -> void:
	var area := Rect2(to_global(arena.position), arena.size).grow(-24)
	var spot := area.get_center()
	for attempt in 60:
		spot = Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y))
		if _floor_free(spot) and spot.distance_to(boss.global_position) > 70.0 and spot.distance_to(_game.player.global_position) > 60.0:
			break
	var potion: HeartPotion = POTION.instantiate()
	potion.position = actors.to_local(spot)
	potion.taken.connect(_on_potion_taken.bind(potion))
	actors.add_child(potion)
	_game.notify([_game.data.message("boss_potion")], 3.0)


## ¿No hay nada sólido (columnas, muros) a menos de 14 px de ese punto?
func _floor_free(spot: Vector2) -> bool:
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, spot)
	query.exclude = [_game.player.get_rid(), boss.get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _on_potion_taken(potion: HeartPotion) -> void:
	if _game.health.halves >= _game.health.max_halves:
		return    # con los corazones llenos, la poción se queda para después
	_game.health.heal(int(_game.combat("potion_heal", 2)))
	potion.queue_free()


func restart_after_death() -> void:
	super()
	boss.reset_for_retry()
	get_tree().call_group("potions", "queue_free")


func _on_boss_defeated() -> void:
	open_exit()
	objective_key = "objective_throne_done"
	_game.player.controls_enabled = false
	_game.bus.publish(GameEvents.CORE_TAKEN)
	_game.notify([_game.data.message("boss_beaten")], 4.0)
	await get_tree().create_timer(3.0).timeout
	_game.finish(true)
