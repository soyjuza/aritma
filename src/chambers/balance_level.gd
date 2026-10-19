## Sala 4 — La Balanza de los Aritmanos (escena: scenes/niveles/sala_4_balanza.tscn).
## Se entra por un pasillo con prensas más rápidas que las de la Sala 2. En la sala, la Balanza
## sobre el pozo de lava: hay que repartir todas las pesas en los dos platos para que sumen lo
## mismo, con dos juegos de pesas (uno se ve, el otro está oculto). Los errores despiertan a
## los guardianes, como en las Salas 1 y 2.
class_name BalanceLevel
extends ChamberLevel

var _in_hall := false

@onready var machine: BalanceMachine = $Actores/Balanza


func wire() -> void:
	var periods: Array = data.get("press_periods", [])
	var presses := nodes_of(Crusher)
	for i in presses.size():
		if i < periods.size():
			presses[i].period = float(periods[i])
		presses[i].crushed.connect(_on_crushed)
	machine.setup(kit, _game.bus, data, func(key, args): return _game.data.message(key, args), _open_machine)
	machine.solved.connect(_on_solved)
	$Zonas/EntradaSala.crossed.connect(_on_hall_entered)


func _on_crushed() -> void:
	_game.bus.publish(GameEvents.PLAYER_FELL)
	_game.penalize(float(_game.combat("fall_penalty_sec", 7)))
	_game.notify([_game.data.message("player_crushed")], 2.5)
	respawn_player()


func _on_hall_entered() -> void:
	_in_hall = true
	objective_key = "objective_balance_machine"
	_game.dialog.say(data.get("intro", []))


func _open_machine() -> void:
	if machine_blocked():
		return
	if machine.is_solved:
		_game.dialog.say([_game.data.message("balance_already")])
		return
	_game.open_codex(machine.session)


func _on_solved() -> void:
	objective_key = "objective_balance_done"
	open_exit()
