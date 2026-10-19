## Sala 5 — La Singularidad del Cero (escena: scenes/niveles/sala_5_singularidad.tscn). La final.
## Un pasillo sin trampas lleva a la antesala, frente al abismo. Allí la Consola de la Red:
## hay que programar una búsqueda de un camino (en anchura, por ejemplo) por las plataformas
## flotantes. Con el programa aceptado, el atril levanta los puentes de ese camino (en
## chambers.json, "life" 0 = quedan para siempre) y se camina por ellos hasta el núcleo.
## Tomar el núcleo lleva a la Sala 6, la del jefe final.
## Fuera de las plataformas y de los puentes, Tala cae al abismo (−7 s). Los errores de la
## consola despiertan a los guardianes, que no pueden entrar al abismo.
class_name CoreLevel
extends ChamberLevel

var _in_hall := false
var _won := false

@onready var machine: NetworkConsole = $Actores/Consola
@onready var network: SkyNetwork = $Red


func wire() -> void:
	machine.setup(_game.bus, data, func(key, args): return _game.data.message(key, args), _use_console, network.positions(), network.show_network)
	machine.view_focus = machine.to_local(network.to_global(network.void_rect.get_center()))
	machine.solved.connect(_on_ready)
	$Zonas/EntradaSala.crossed.connect(_on_hall_entered)


func _on_hall_entered() -> void:
	_in_hall = true
	if not machine.is_solved:
		objective_key = "objective_core_machine"
	_game.dialog.say(data.get("intro", []))


## El atril: antes de resolver, abre el Códice; después, levanta los puentes.
func _use_console() -> void:
	if machine_blocked():
		return
	if not machine.is_solved:
		_game.open_codex(machine.session)
		return
	if network.bridges_up():
		return
	var timing: Dictionary = data.get("bridges", {})
	network.raise(machine.path, float(timing.get("first_delay", 0.8)), float(timing.get("interval", 0.35)), float(timing.get("life", 4.5)))
	_game.bus.publish(GameEvents.BRIDGES_RAISED)
	_game.notify([_game.data.message("bridges_up")], 3.0)


func _on_ready() -> void:
	objective_key = "objective_core_bridges"
	(machine.get_node("Atril/Uso") as Interactable).prompt_key = "prompt_bridges"


func _physics_process(_delta: float) -> void:
	var player: PlayerController = _game.player if _game else null
	if player == null or _won or player.falling or player.airborne or player.dead or player.get_parent() != actors:
		return
	if not _game.machine.current is PlayState:
		return
	if player.global_position.distance_to(network.platform_global(network.goal_id())) < 9.0:
		_take_core()
	elif not network.is_ground(player.global_position):
		_fall_into_void()


func restart_after_death() -> void:
	network.collapse()
	super()


func _fall_into_void() -> void:
	if float(data.get("bridges", {}).get("life", 4.5)) > 0.0:
		network.collapse()
	player_fall()


func player_fall() -> void:
	await _game.player.fall()
	_on_player_fell()


## Tala toma el núcleo: se abre el camino a la Sala 6 (o, si no hay más salas, se gana).
func _take_core() -> void:
	_won = true
	network.core_taken = true
	_game.player.controls_enabled = false
	_game.bus.publish(GameEvents.CORE_TAKEN)
	_game.rig.shake(5.0)
	_game.notify([_game.data.message("core_taken")], 4.0)
	await get_tree().create_timer(2.0).timeout
	solved = true
	alarm.calm()
	if _game.data.chamber_count() > index + 1:
		_game.enter_chamber(index + 1)
	else:
		_game.finish(true)
