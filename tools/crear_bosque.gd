## Crea el mapa del Bosque (capítulo 2) en scenes/niveles/bosque.tscn.
## Uso: Godot --headless --path . -s tools/crear_bosque.gd
## Toma el suelo y la fachada del pueblo y lo llena de árboles. Volver a correrlo pisa la escena.
extends SceneTree

const BIG := preload("res://scenes/objetos/arbol_grande.tscn")
const SMALL := preload("res://scenes/objetos/arbol_chico.tscn")
const SIGN := preload("res://scenes/objetos/letrero.tscn")
const ITEM := preload("res://scenes/objetos/engranaje.tscn")
const PEOPLE := {
	"Sauce": ["res://scenes/personajes/sauce.tscn", Vector2(328, 392)],
	"Ramas": ["res://scenes/personajes/ramas.tscn", Vector2(200, 272)],
	"Lia": ["res://scenes/personajes/lia.tscn", Vector2(392, 248)],
}
const SIGN_AT := Vector2(248, 176)
const MUSHROOM_AT := Vector2(72, 392)


func _init() -> void:
	var town: Node2D = load("res://scenes/niveles/pueblo.tscn").instantiate()
	var root := Node2D.new()
	root.name = "Bosque"
	root.set_script(load("res://src/world/hub_level.gd"))
	root.set("music_key", "town")
	root.set("bounds", town.get("bounds"))
	root.set("spawn_facing", Vector2.UP)
	for layer in ["Suelo", "Detalles", "Muros"]:
		root.add_child(town.get_node(layer).duplicate())
	var actors := _node(root, "Actores")
	actors.y_sort_enabled = true
	_node(root, "Efectos").z_index = 20
	root.add_child(town.get_node("Bordes").duplicate())
	var zones := _node(root, "Zonas")
	var entrance: Node = town.get_node("Zonas/EntradaTemplo").duplicate()
	entrance.name = "EntradaRuinas"
	zones.add_child(entrance)
	# Personajes, letrero y hongo
	var keep: Array = [SIGN_AT, MUSHROOM_AT]
	for n in PEOPLE:
		var npc: Node2D = load(PEOPLE[n][0]).instantiate()
		npc.name = n
		npc.position = PEOPLE[n][1]
		actors.add_child(npc)
		keep.append(PEOPLE[n][1])
	var sign: Node2D = SIGN.instantiate()
	sign.name = "Letrero"
	sign.position = SIGN_AT
	sign.set("lines_key", "sign")
	actors.add_child(sign)
	var mushroom: Node2D = ITEM.instantiate()
	mushroom.name = "Hongo"
	mushroom.position = MUSHROOM_AT
	mushroom.set("item_id", "hongo_1")
	mushroom.set("quest_id", "hongos")
	mushroom.set("look", "mushroom")
	actors.add_child(mushroom)
	_plant(actors, keep)
	var mood := CanvasModulate.new()
	mood.name = "Ambiente"
	mood.color = Color(0.74, 0.86, 0.76)
	root.add_child(mood)
	var start := Marker2D.new()
	start.name = "Inicio"
	start.position = Vector2(288, 440)
	root.add_child(start)
	_own(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	print("bosque -> ", error_string(ResourceSaver.save(packed, "res://scenes/niveles/bosque.tscn")))
	town.free()
	root.free()
	quit()


## Árboles por todo el mapa, menos el camino, la plaza de las ruinas y lo que hay que ver.
func _plant(actors: Node2D, keep: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var count := 0
	for y in range(136, 480, 30):
		for x in range(20, 576, 30):
			var at := Vector2(x + rng.randi_range(-6, 6), y + rng.randi_range(-6, 6))
			if absf(at.x - 288.0) < 52.0:
				continue
			if at.y > 400.0 and absf(at.x - 288.0) < 90.0:
				continue
			if keep.any(func(p): return at.distance_to(p) < 44.0):
				continue
			if rng.randf() < 0.35 and x > 40 and x < 540 and y < 450:
				continue
			var tree: Node2D = (BIG if rng.randf() < 0.6 else SMALL).instantiate()
			count += 1
			tree.name = "Arbol%d" % count
			tree.position = at
			actors.add_child(tree)


func _node(parent: Node, node_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = node_name
	parent.add_child(n)
	return n


func _own(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		if child.scene_file_path == "":
			_own(child, root)
