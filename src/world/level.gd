## Nivel base (pueblo o sala). Conecta lo que hay en la escena.
class_name Level
extends Node2D

@export var title := ""
@export var music_key := "temple"
@export var objective_key := ""
@export var spawn_facing := Vector2.DOWN
@export var dark := false
@export var bounds := Rect2i()

var kit: TileKit
var data: Dictionary = {}
var spawn := Vector2.ZERO
var checkpoint := Vector2.ZERO

var _game

@onready var ground: TileMapLayer = $Suelo
@onready var detail: TileMapLayer = $Detalles
@onready var walls: TileMapLayer = $Muros
@onready var actors: Node2D = $Actores
@onready var fx: Node2D = $Efectos


func setup(game, p_kit: TileKit) -> void:
	_game = game
	kit = p_kit
	if data.is_empty():
		data = default_data()
	spawn = ($Inicio as Marker2D).position
	checkpoint = spawn
	_wire_common()
	wire()


func default_data() -> Dictionary:
	return {}


## Cada nivel conecta lo suyo.
func wire() -> void:
	pass


## Punto para la cámara del título.
func title_point() -> Vector2:
	return ($PuntoTitulo as Marker2D).position if has_node("PuntoTitulo") else spawn


## Acciones propias del nivel. true si las usó.
func handle_action(_actions: Array) -> bool:
	return false


func action_prompt() -> Dictionary:
	return {}


## Texto extra para el HUD.
func hud_line() -> String:
	return ""


## Sombras y partículas según la calidad.
func apply_quality(profile: QualityProfile) -> void:
	for light in find_children("*", "PointLight2D", true, false):
		(light as PointLight2D).shadow_enabled = profile.shadows() and light.get_meta("casts_shadow", false)
	for p in find_children("*", "CPUParticles2D", true, false):
		if not p.has_meta("base_amount"):
			p.set_meta("base_amount", p.amount)
		p.amount = maxi(2, int(p.get_meta("base_amount") * kit.particle_scale))


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * TileKit.TILE) + Vector2(TileKit.TILE, TileKit.TILE) / 2.0


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


## Tala sin corazones: vuelve al punto seguro.
func restart_after_death() -> void:
	respawn_player()


## Lo que se guarda del nivel.
func save_state() -> Dictionary:
	return {}
