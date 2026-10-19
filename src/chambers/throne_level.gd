## Sala 6 — El Trono del Cero (escena: scenes/niveles/sala_6_trono.tscn). El jefe final.
## Sin máquina ni código: al entrar a la sala, el Guardián del Cero (ZeroBoss) despierta y hay
## que vencerlo. Al cambiar de fase llama olas de guardianes (el Director de Alarma de la sala,
## con los puntos «Guardianes/Caidas»). Vencerlo gana el juego.
## Al aparecer el jefe, Tala recupera corazones: es la única curación del juego.
class_name ThroneLevel
extends ChamberLevel

## Dónde puede caer el pisotón del jefe (el piso de la sala, sin los muros).
@export var arena := Rect2(48, 56, 400, 250)

var _in_hall := false
var _framing := false       # la cámara muestra al jefe mientras se lee la presentación

@onready var boss: ZeroBoss = $Actores/JefeCero


func wire() -> void:
	boss.setup(_game.bus, alarm)
	boss.hold_while = _game.dialog.is_open
	boss.arena = Rect2(to_global(arena.position), arena.size)
	boss.defeated.connect(_on_boss_defeated)
	boss.shielded.connect(func(): _game.notify([_game.data.message("boss_shield")], 4.0))
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


func _physics_process(_delta: float) -> void:
	if _framing and not _game.dialog.is_open():
		_framing = false
		_game.follow_player()


func restart_after_death() -> void:
	super()
	boss.reset_for_retry()


func _on_boss_defeated() -> void:
	open_exit()
	objective_key = "objective_throne_done"
	_game.player.controls_enabled = false
	_game.bus.publish(GameEvents.CORE_TAKEN)
	_game.notify([_game.data.message("boss_beaten")], 4.0)
	await get_tree().create_timer(3.0).timeout
	_game.finish(true)
