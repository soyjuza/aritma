## Sala 4 — La Mesa de las Figuras (escena: scenes/niveles/sala_4_figuras.tscn).
## Se entra por un pasillo con prensas más rápidas que las de la Sala 2. En la sala, la Mesa
## de las Figuras: desde su atril se abre un rompecabezas (PuzzleState) donde hay que llenar
## una figura grande con piezas más pequeñas, sin que sobre ni falte nada. Son dos figuras
## seguidas (en chambers.json, "puzzles"). Esta sala no es de código, es de razonamiento.
class_name FigureLevel
extends ChamberLevel

var _in_hall := false
var _rng := RandomNumberGenerator.new()

@onready var table: FigureTable = $Actores/MesaFiguras


func wire() -> void:
	var periods: Array = data.get("press_periods", [])
	var presses := nodes_of(Crusher)
	for i in presses.size():
		if i < periods.size():
			presses[i].period = float(periods[i])
		presses[i].crushed.connect(_on_crushed)
	var seed_value := int(data.get("seed", 0))
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	table.setup(data, _rng, _open_table)
	table.solved.connect(_on_solved)
	$Zonas/EntradaSala.crossed.connect(_on_hall_entered)


func _on_crushed() -> void:
	_game.bus.publish(GameEvents.PLAYER_FELL)
	_game.penalize(float(_game.combat("fall_penalty_sec", 7)))
	_game.notify([_game.data.message("player_crushed")], 2.5)
	respawn_player()


func _on_hall_entered() -> void:
	_in_hall = true
	objective_key = "objective_figures_table"
	_game.dialog.say(data.get("intro", []))


func _open_table() -> void:
	if table.is_solved:
		_game.dialog.say([_game.data.message("figures_already")])
		return
	_game.machine.change("puzzle", {"table": table})


## Cargando una partida con la Mesa ya resuelta: las figuras quedan llenas.
func restore_solved() -> void:
	while not table.advance():
		pass


func _on_solved() -> void:
	objective_key = "objective_figures_done"
	open_exit()
