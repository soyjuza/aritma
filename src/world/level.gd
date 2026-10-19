## Un nivel jugable en 2D (el pueblo o una sala), armado como escena (.tscn) en el editor:
## capas de tiles (Suelo, Detalles, Muros: lo que se pinta en Muros es sólido y hace sombra),
## los Actores (ordenados por altura, y-sort), los Efectos, los Bordes, las Zonas y los Fosos.
## El script no construye nada: al cargar el nivel conecta lo que encuentra en la escena
## (letreros, personajes, puntos seguros, fosos) y cada nivel agrega lo suyo en wire().
class_name Level
extends Node2D

@export var title := ""
@export var music_key := "temple"
@export var objective_key := ""
@export var spawn_facing := Vector2.DOWN
## En lo oscuro, el Códice de Tala ilumina un poco.
@export var dark := false
## Celdas que puede mostrar la cámara.
@export var bounds := Rect2i()

var kit: TileKit
var data: Dictionary = {}
var spawn := Vector2.ZERO
var checkpoint := Vector2.ZERO

var _game

@onready var ground: TileMapLayer = $Suelo
@onready var detail: TileMapLayer = $Detalles
@onready var walls: TileMapLayer = $Muros
@onready var actors: Node2D = $Actores     # personajes y objetos altos: se ordenan por y
@onready var fx: Node2D = $Efectos         # efectos por encima de todo


func setup(game, p_kit: TileKit) -> void:
	_game = game
	kit = p_kit
	if data.is_empty():
		data = default_data()
	spawn = ($Inicio as Marker2D).position
	checkpoint = spawn
	_wire_common()
	wire()


## Datos del nivel cuando no los trajo su creador (el pueblo los toma de config.json).
func default_data() -> Dictionary:
	return {}


## Conecta lo propio del nivel (lo redefine cada nivel).
func wire() -> void:
	pass


## Punto que mira la cámara en el título y los menús (el Marker2D «PuntoTitulo», si hay).
func title_point() -> Vector2:
	return ($PuntoTitulo as Marker2D).position if has_node("PuntoTitulo") else spawn


## Acciones propias del nivel (por ejemplo, destapar baldosas). Devuelve true si las usó.
func handle_action(_actions: Array) -> bool:
	return false


## Ayuda de teclas propia del nivel: {"key": "E", "text": "..."} o {} si no hay.
func action_prompt() -> Dictionary:
	return {}


## Texto extra para el HUD (contadores de la sala). "" = nada.
func hud_line() -> String:
	return ""


## Activa o apaga las sombras de las luces y ajusta la cantidad de partículas según la calidad.
func apply_quality(profile: QualityProfile) -> void:
	for light in find_children("*", "PointLight2D", true, false):
		(light as PointLight2D).shadow_enabled = profile.shadows() and light.get_meta("casts_shadow", false)
	for p in find_children("*", "CPUParticles2D", true, false):
		if not p.has_meta("base_amount"):
			p.set_meta("base_amount", p.amount)
		p.amount = maxi(2, int(p.get_meta("base_amount") * kit.particle_scale))


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * TileKit.TILE) + Vector2(TileKit.TILE, TileKit.TILE) / 2.0


## Todos los nodos de la escena de una clase (incluye los de escenas instanciadas).
func nodes_of(kind) -> Array:
	return find_children("*", "", true, false).filter(func(n): return is_instance_of(n, kind))


# ------------------------------------------------------------------ conexiones comunes

func _wire_common() -> void:
	for sign in nodes_of(SignPost):
		sign.reading.used.connect(func(): _game.dialog.say(data.get(sign.lines_key, [])))
	for npc in nodes_of(Npc):
		npc.talk_area.used.connect(func(): _game.talk(npc.talk_key))
	for zone in nodes_of(CheckpointZone):
		zone.crossed.connect(func(): set_checkpoint(zone.point()))
	for pit in nodes_of(Pit):
		pit.fell.connect(_on_player_fell)


func set_checkpoint(at: Vector2) -> void:
	checkpoint = at
	_game.bus.publish(GameEvents.CHECKPOINT)


func _on_player_fell() -> void:
	_game.bus.publish(GameEvents.PLAYER_FELL)
	_game.penalize(float(_game.combat("fall_penalty_sec", 7)))
	_game.notify([_game.data.message("player_fell")], 2.5)
	await get_tree().create_timer(0.7).timeout
	respawn_player()


func respawn_player() -> void:
	_game.player.place(checkpoint, Vector2.UP)
	_game.bus.publish(GameEvents.PLAYER_RESET)
