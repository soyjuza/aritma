## El pueblo. La puerta del templo se abre con SELECT * FROM puerta.
class_name TownLevel
extends Level

@onready var gate: GateMachine = $Actores/AtrilPuerta
@onready var seal: Grate = $SelloTemplo


func default_data() -> Dictionary:
	return _game.data.town


func wire() -> void:
	gate.on_open(open_gate)
	gate.setup(_game.bus, data.get("gate", {}), func(key, args): return _game.data.message(key, args), func(): _game.open_codex(gate.session))
	if _game.reached > 0:
		# El templo ya se superó: la puerta queda abierta
		seal.open()
		gate.mark_solved()
	gate.solved.connect(func(): objective_key = "objective_town_open")
	$Zonas/EntradaTemplo.crossed.connect(func(): _game.enter_temple())


func open_gate() -> void:
	_game.bus.publish(GameEvents.DOOR_OPENED, {"door": "templo"})
	seal.open()
	await get_tree().create_timer(0.6).timeout
