## El pueblo de Raíz (escena: scenes/niveles/pueblo.tscn), levantado sobre las ruinas de
## Aritma. Al norte, la fachada del templo con la puerta sellada: se abre programando su atril
## (puerta.abrir()). Orun espera junto al camino.
class_name TownLevel
extends Level

@onready var gate: GateMachine = $Actores/AtrilPuerta
@onready var seal: Grate = $SelloTemplo


func default_data() -> Dictionary:
	return _game.data.town


func wire() -> void:
	gate.setup(data, func(key, args): return _game.data.message(key, args), open_gate, close_gate, func(): _game.open_codex(gate.session))
	gate.solved.connect(func(): objective_key = "objective_town_open")
	# Al cruzar la puerta abierta se entra al templo
	$Zonas/EntradaTemplo.crossed.connect(func(): _game.enter_temple())


func open_gate() -> void:
	_game.bus.publish(GameEvents.DOOR_OPENED, {"door": "templo"})
	seal.open()
	await get_tree().create_timer(0.6).timeout


func close_gate() -> void:
	seal.close()
