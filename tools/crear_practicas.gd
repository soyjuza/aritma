## Crea las escenas de las salas de práctica en scenes/practicas/.
## Uso: Godot --headless --path . -s tools/crear_practicas.gd
## Después se pueden editar a mano en el editor; volver a correrlo las pisa.
extends SceneTree

const T := 16
const OUT := "res://scenes/practicas/"
const TORCH := preload("res://scenes/objetos/antorcha.tscn")
const BRAZIER := preload("res://scenes/objetos/brasero.tscn")
const COLUMN := preload("res://scenes/objetos/columna.tscn")
const LECTERN := preload("res://scenes/maquinas/atril.tscn")
const PIT := preload("res://src/world/pit.gd")
const ZONE := preload("res://src/world/trigger_zone.gd")
const EXIT := preload("res://src/chambers/exit_zone.gd")

var sample: Node


func _init() -> void:
	sample = load("res://scenes/niveles/sala_3_vortice.tscn").instantiate()
	DirAccess.make_dir_recursive_absolute(OUT)
	_save(_pasos(), "practica_1_pasos")
	_save(_pelea(), "practica_2_pelea")
	_save(_bloques(), "practica_3_bloques")
	_save(_funciones(), "practica_4_funciones")
	_save(_buscaminas(), "practica_5_buscaminas")
	sample.free()
	quit()


# ------------------------------------------------------------------ salas

func _pasos() -> Node2D:
	var w := 13
	var h := 34
	var root := _room("Practica1Pasos", "res://src/practice/practice_move_level.gd", w, h)
	var pasos := _node(root, "Pasos")
	for z in [["caminar", 27], ["correr", 18], ["saltar", 12], ["foso_largo", 5]]:
		_zone(pasos, z[0], Vector2(w * T / 2.0, z[1] * T + 8), Vector2((w - 2) * T, 10), false)
		_marker(root.get_node("Marcas"), z[0], Vector2(w * T / 2.0, z[1] * T + 8))
	var pits := _node(root, "Fosos")
	_pit(root, pits, "FosoCorto", 1, 14, w - 2, 2)
	_pit(root, pits, "FosoLargo", 1, 7, w - 2, 3)
	for y in [8, 16, 24, 30]:
		_torches(root, w, y)
	return root


func _pelea() -> Node2D:
	var w := 19
	var h := 16
	var root := _room("Practica2Pelea", "res://src/practice/practice_fight_level.gd", w, h)
	var dummy := Node2D.new()
	dummy.name = "Muneco"
	dummy.set_script(load("res://src/practice/training_dummy.gd"))
	dummy.position = Vector2(w * T / 2.0, 9 * T)
	root.get_node("Actores").add_child(dummy)
	var body := StaticBody2D.new()
	body.name = "Cuerpo"
	dummy.add_child(body)
	var shape := CollisionShape2D.new()
	shape.name = "Forma"
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	body.add_child(shape)
	_marker(root.get_node("Marcas"), "Caida", Vector2(w * T / 2.0, 6 * T))
	for at in [Vector2(3, 5), Vector2(w - 4, 5), Vector2(3, 12), Vector2(w - 4, 12)]:
		_put(root.get_node("Actores"), COLUMN, "Columna", at * T + Vector2(8, 8))
	for y in [6, 11]:
		_torches(root, w, y)
	return root


func _bloques() -> Node2D:
	var w := 15
	var h := 13
	var root := _room("Practica3Bloques", "res://src/practice/practice_code_level.gd", w, h)
	var braziers := _node(root.get_node("Actores"), "Braseros")
	braziers.y_sort_enabled = true
	for i in 5:
		_put(braziers, BRAZIER, "Brasero%d" % (i + 1), Vector2((3 + i * 2) * T + 8, 5 * T))
	_machine(root, "res://src/practice/torch_machine.gd", Vector2(w * T / 2.0, 9 * T))
	for y in [6, 10]:
		_torches(root, w, y)
	return root


func _funciones() -> Node2D:
	var w := 15
	var h := 13
	var root := _room("Practica4Funciones", "res://src/practice/practice_code_level.gd", w, h)
	_machine(root, "res://src/practice/function_machine.gd", Vector2(w * T / 2.0, 10 * T))
	for y in [6, 10]:
		_torches(root, w, y)
	return root


func _buscaminas() -> Node2D:
	var w := 13
	var h := 13
	var root := _room("Practica5Buscaminas", "res://src/practice/practice_mines_level.gd", w, h)
	var board := Node2D.new()
	board.name = "Tablero"
	board.set_script(load("res://src/chambers/mine_board.gd"))
	board.z_index = -5
	board.position = Vector2(4 * T, 5 * T)
	board.set("cols", 5)
	board.set("rows", 4)
	root.add_child(board)
	root.move_child(board, root.get_node("Actores").get_index())
	for y in [6, 10]:
		_torches(root, w, y)
	return root


# ------------------------------------------------------------------ piezas

## Sala rectangular con puerta y reja arriba.
func _room(room_name: String, script_path: String, w: int, h: int) -> Node2D:
	var root := Node2D.new()
	root.name = room_name
	root.set_script(load(script_path))
	root.set("spawn_facing", Vector2.UP)
	# La cámara ve unas 28 x 16 baldosas: la sala queda centrada
	var px := maxi(0, (29 - w) / 2)
	var py := maxi(0, (17 - h) / 2)
	root.set("bounds", Rect2i(-px, -py, w + px * 2, h + py * 2))
	for layer in ["Suelo", "Detalles", "Muros"]:
		var copy: TileMapLayer = sample.get_node(layer).duplicate()
		copy.clear()
		root.add_child(copy)
	_node(root, "Actores").y_sort_enabled = true
	_node(root, "Efectos")
	_node(root, "Marcas")
	var gx := w / 2 - 1
	_paint(root, w, h, gx)
	var grate: Node2D = sample.get_node("Reja").duplicate()
	grate.position = Vector2(gx * T, 2 * T)
	root.add_child(grate)
	_zone(_node(root, "Zonas"), "Salida", Vector2(gx * T + T, 6), Vector2(32, 12), false, EXIT)
	var mood := CanvasModulate.new()
	mood.name = "Ambiente"
	mood.color = Color(0.8, 0.77, 0.84)
	root.add_child(mood)
	var start := Marker2D.new()
	start.name = "Inicio"
	start.position = Vector2(w * T / 2.0, (h - 3) * T + 8)
	root.add_child(start)
	return root


func _paint(root: Node2D, w: int, h: int, gx: int) -> void:
	var ground: TileMapLayer = root.get_node("Suelo")
	var walls: TileMapLayer = root.get_node("Muros")
	for y in range(0, h - 1):
		for x in range(1, w - 1):
			if y >= 3 or x == gx or x == gx + 1:
				ground.set_cell(Vector2i(x, y), 2, Vector2i(12 + x % 8, 12 + y % 4))
	var cycle := [6, 8, 6, 8, 6, 7]
	for x in range(0, w):
		var top := Vector2i(cycle[x % 6], 6)
		if x == 0:
			top = Vector2i(5, 6)
		elif x == w - 1:
			top = Vector2i(9, 6)
		if x != gx and x != gx + 1:
			walls.set_cell(Vector2i(x, 2), 0, top)
		var bottom := Vector2i(5 if x == 0 else (9 if x == w - 1 else cycle[x % 6]), 10)
		walls.set_cell(Vector2i(x, h - 1), 0, bottom)
	for y in range(3, h - 1):
		var side := 8 if y == h - 2 else (7 if y % 2 == 1 else 9)
		walls.set_cell(Vector2i(0, y), 0, Vector2i(5, side))
		walls.set_cell(Vector2i(w - 1, y), 0, Vector2i(9, side))
	# Pasillo de la salida
	for y in [0, 1]:
		walls.set_cell(Vector2i(gx - 1, y), 0, Vector2i(5, 7 if y == 0 else 9))
		walls.set_cell(Vector2i(gx + 2, y), 0, Vector2i(9, 7 if y == 0 else 9))
	for i in 4:
		walls.set_cell(Vector2i(gx - 1 + i, -1), 0, Vector2i([5, 6, 8, 9][i], 6))


## Foso de lado a lado.
func _pit(root: Node2D, parent: Node, pit_name: String, x: int, y: int, cols: int, rows: int) -> void:
	var ground: TileMapLayer = root.get_node("Suelo")
	for r in rows:
		for c in cols:
			var ax := 0 if c == 0 else (3 if c == cols - 1 else 1 + c % 2)
			var ay := 0 if r == 0 else (2 if r == rows - 1 else 1)
			ground.set_cell(Vector2i(x + c, y + r), 3, Vector2i(ax, ay))
	var pit := Node2D.new()
	pit.name = pit_name
	pit.set_script(PIT)
	pit.position = Vector2(x * T, y * T)
	pit.set("size", Vector2(cols * T, rows * T))
	parent.add_child(pit)


func _torches(root: Node2D, w: int, y: int) -> void:
	_put(root.get_node("Efectos"), TORCH, "Antorcha", Vector2(14, y * T + 6))
	_put(root.get_node("Efectos"), TORCH, "Antorcha", Vector2((w - 1) * T + 2, y * T + 6))


func _machine(root: Node2D, script_path: String, at: Vector2) -> void:
	var machine := Node2D.new()
	machine.name = "Maquina"
	machine.set_script(load(script_path))
	machine.position = at
	root.get_node("Actores").add_child(machine)
	_put(machine, LECTERN, "Atril", Vector2.ZERO)


func _zone(parent: Node, zone_name: String, at: Vector2, size: Vector2, once: bool, script: Script = ZONE) -> Area2D:
	var zone := Area2D.new()
	zone.name = zone_name
	zone.set_script(script)
	zone.position = at
	zone.collision_layer = 0
	zone.set("once", once)
	var shape := CollisionShape2D.new()
	shape.name = "Forma"
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	zone.add_child(shape)
	parent.add_child(zone)
	return zone


func _marker(parent: Node, marker_name: String, at: Vector2) -> void:
	var m := Marker2D.new()
	m.name = marker_name
	m.position = at
	parent.add_child(m)


func _put(parent: Node, scene: PackedScene, node_name: String, at: Vector2) -> Node2D:
	var n: Node2D = scene.instantiate()
	n.name = node_name
	n.position = at
	parent.add_child(n, true)
	return n


func _node(parent: Node, node_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = node_name
	parent.add_child(n)
	return n


func _save(root: Node, file: String) -> void:
	_own(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	var err := ResourceSaver.save(packed, OUT + file + ".tscn")
	print(file, " -> ", error_string(err))
	root.free()


## Todos los nodos quedan guardados en la escena (las instancias, solo su raíz).
func _own(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		if child.scene_file_path == "":
			_own(child, root)
