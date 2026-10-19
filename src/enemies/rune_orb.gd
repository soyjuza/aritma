## Orbe del hechicero (escena: scenes/enemigos/orbe.tscn): vuela en línea recta, se deshace
## contra los muros y, si toca a Tala, le quita medio corazón. Un golpe de garrote lo deshace.
class_name RuneOrb
extends Node2D

@export var speed := 95.0
@export var life := 2.6

var velocity := Vector2.ZERO
var damage := 1
var color := Color(0.75, 0.4, 1.0)

var _t := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _light: PointLight2D = $Luz


func _ready() -> void:
	add_to_group("orbs")
	z_index = 4
	_light.color = color


func _physics_process(delta: float) -> void:
	_t += delta
	position += velocity * delta
	_sprite.frame = int(_t * 12.0) % _sprite.hframes
	if _t >= life:
		shatter()
		return
	var player: PlayerController = get_tree().get_first_node_in_group("player")
	if player and not player.dead and not player.airborne and global_position.distance_to(player.global_position + Vector2(0, -4)) < 7.0:
		player.hurt(damage, global_position)
		shatter()
		return
	if _hits_wall():
		shatter()


func _hits_wall() -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position + Vector2(0, 5)
	query.collide_with_bodies = true
	query.collision_mask = 1
	for hit in get_world_2d().direct_space_state.intersect_point(query, 4):
		if hit.collider is StaticBody2D or hit.collider is TileMapLayer:
			return true
	return false


## Se deshace en chispas (contra un muro, contra Tala o de un garrotazo).
func shatter() -> void:
	if is_queued_for_deletion():
		return
	var puff := NumberBurst.new()
	puff.count = 4
	puff.tint = color
	puff.position = position
	get_parent().add_child(puff)
	queue_free()
