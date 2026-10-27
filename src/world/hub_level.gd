## Mapa del mundo (Bosque, Cueva...). La entrada de las ruinas lleva a sus salas.
class_name HubLevel
extends Level

var _framing := false


func wire() -> void:
	if _game.reached <= int(data.get("chapter", 0)):
		objective_key = String(data.get("objective_key", ""))
	$Zonas/EntradaRuinas.crossed.connect(func(): _game.enter_temple())
	if has_node("Zonas/Balcon"):
		$Zonas/Balcon.crossed.connect(_show_view)


## El Mirador: la cámara baja a mostrar el valle mientras se lee.
func _show_view() -> void:
	_framing = true
	_game.rig.frame(($Vista as Marker2D).global_position, 1.0, 1.4)
	_game.dialog.say(data.get("view", []))


func _physics_process(_delta: float) -> void:
	if _framing and not _game.dialog.is_open():
		_framing = false
		_game.follow_player()
