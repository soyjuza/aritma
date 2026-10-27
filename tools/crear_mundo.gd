## Crea los mapas del mundo: abre el camino del este en Raíz y arma Bosque, Cueva, Mirador y Cima.
## Uso: Godot --headless --path . -s tools/crear_mundo.gd
## Volver a correrlo pisa las escenas (menos el pueblo, que solo se retoca).
extends SceneTree

const TOWN := "res://scenes/niveles/pueblo.tscn"
const NATURE := preload("res://assets/pack/backgrounds/Tilesets/TilesetNature.png")
const BIG := preload("res://scenes/objetos/arbol_grande.tscn")
const SMALL := preload("res://scenes/objetos/arbol_chico.tscn")
const SIGN := preload("res://scenes/objetos/letrero.tscn")
const ITEM := preload("res://scenes/objetos/engranaje.tscn")
const ROCKS := preload("res://scenes/objetos/rocas.tscn")
const LIGHT := preload("res://assets/efectos/luz_suave.tres")
const PANORAMA := "res://assets/fondos/panorama.png"

const W := 36
const H := 30
const T := 16
## Fila del camino que cruza de oeste a este (dos baldosas de alto).
const ROAD := 15

## Juegos de baldosas de TilesetFloor (fuente 0): mancha 3×3 y relleno.
const GRASS := {"blob": Vector2i(0, 7), "fill": Vector2i(0, 12)}
const CAVE := {"blob": Vector2i(11, 14), "fill": Vector2i(11, 19)}
const HIGH := {"blob": Vector2i(11, 7), "fill": Vector2i(11, 12)}
const SNOW := {"blob": Vector2i(0, 14), "fill": Vector2i(0, 19)}

## Piezas de TilesetNature (región en píxeles, alto del tronco para el choque).
const BOULDER := Rect2(256, 128, 32, 32)
const BOULDER_SMALL := Rect2(288, 144, 16, 16)
const BOULDER_BROWN := Rect2(208, 128, 32, 32)
const PINE := Rect2(160, 0, 32, 32)
const PINE_BIG := Rect2(128, 80, 64, 48)
const DEAD_TREE := Rect2(64, 0, 32, 32)
const CRYSTALS := [Rect2(0, 224, 16, 16), Rect2(16, 224, 16, 16), Rect2(32, 224, 16, 16), Rect2(48, 224, 16, 16)]
const CRYSTAL_COLORS := [Color("ffb26b"), Color("6bd5ff"), Color("e08cff"), Color("b6ff6b")]

var _town: Node2D
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_town = load(TOWN).instantiate()
	_edit_town()
	_save(_forest(), "res://scenes/niveles/bosque.tscn")
	_save(_cave(), "res://scenes/niveles/cueva.tscn")
	_save(_lookout(), "res://scenes/niveles/mirador.tscn")
	_save(_peak(), "res://scenes/niveles/cima.tscn")
	_town.free()
	quit()


# ------------------------------------------------------------------ Raíz

## Camino al este, salida al Bosque tapada por rocas y marcadores de llegada.
func _edit_town() -> void:
	var town: Node2D = load(TOWN).instantiate()
	var ground: TileMapLayer = town.get_node("Suelo")
	var road := _cells(Rect2i(19, ROAD, W - 19, 2))
	for c in road:
		ground.set_cell(c, 0, GRASS.blob + Vector2i(1, 1))
		(town.get_node("Detalles") as TileMapLayer).erase_cell(c)
	_repaint(ground, GRASS, Rect2i(14, ROAD - 3, W - 14, 7))
	var actors: Node2D = town.get_node("Actores")
	var lane := Rect2(19 * T - 8, ROAD * T - 10, W * T, 2 * T + 18)
	for a in actors.get_children():
		if not a is Npc and lane.has_point(a.position):
			a.free()
	for n in ["Zonas/SalidaEste", "Entradas", "Bordes"]:
		if town.has_node(n):
			town.get_node(n).free()
	_borders(town, {"east": ROAD})
	_exit(town, "SalidaEste", "east", ROAD, "bosque", "Oeste")
	_barrier(actors, "east", ROAD, 1, "barrier_forest")
	_entries(town, {"Este": ["east", ROAD], "Puerta": Vector2(288, 136)})
	_save(town, TOWN)


# ------------------------------------------------------------------ Bosque

func _forest() -> Node2D:
	var root := _base("Bosque", GRASS, Color(0.74, 0.86, 0.76))
	_road(root, GRASS, true, true)
	var actors: Node2D = root.get_node("Actores")
	var keep: Array = []
	keep.append_array(_people(actors, {"Sauce": [Vector2(88, 224), "sauce"], "Ramas": [Vector2(200, 300), "ramas"], "Lia": [Vector2(408, 216), "lia"]}))
	keep.append(_sign(actors, Vector2(248, 216), "sign"))
	keep.append(_pickup(actors, "Hongo", Vector2(72, 392), "hongo_1", "hongos", "mushroom"))
	_exit(root, "SalidaOeste", "west", ROAD, "pueblo", "Este")
	_exit(root, "SalidaEste", "east", ROAD, "cueva", "Oeste")
	_barrier(actors, "east", ROAD, 2, "barrier_cave")
	_borders(root, {"west": ROAD, "east": ROAD})
	_entries(root, {"Oeste": ["west", ROAD], "Este": ["east", ROAD], "Puerta": Vector2(288, 136)})
	var tree := func(_at: Vector2) -> Node2D:
		return (BIG if _rng.randf() < 0.6 else SMALL).instantiate()
	_scatter(actors, root, keep, tree, 2026, GRASS)
	return root


# ------------------------------------------------------------------ Cueva

func _cave() -> Node2D:
	var root := _base("Cueva", CAVE, Color(0.28, 0.26, 0.38))
	root.set("dark", true)
	root.set("music_key", "temple")
	(root.get_node("Muros") as TileMapLayer).modulate = Color(0.75, 0.7, 0.85)
	_road(root, CAVE, true, true)
	var actors: Node2D = root.get_node("Actores")
	var keep: Array = []
	keep.append_array(_people(actors, {"Grava": [Vector2(104, 216), "grava"], "Perla": [Vector2(440, 304), "perla"]}))
	keep.append(_sign(actors, Vector2(248, 216), "sign"))
	keep.append(_pickup(actors, "Cristal", Vector2(504, 120), "cristal_1", "cristales", "crystal"))
	_exit(root, "SalidaOeste", "west", ROAD, "bosque", "Este")
	_exit(root, "SalidaEste", "east", ROAD, "mirador", "Oeste")
	_barrier(actors, "east", ROAD, 3, "barrier_lookout")
	_borders(root, {"west": ROAD, "east": ROAD})
	_entries(root, {"Oeste": ["west", ROAD], "Este": ["east", ROAD], "Puerta": Vector2(288, 136)})
	var count := [0]
	var rock := func(_at: Vector2) -> Node2D:
		count[0] += 1
		if count[0] % 5 == 0:
			return _crystal(count[0])
		return _prop(BOULDER if _rng.randf() < 0.7 else BOULDER_BROWN, 10)
	_scatter(actors, root, keep, rock, 7, CAVE)
	return root


func _crystal(i: int) -> Node2D:
	var k := i % CRYSTALS.size()
	var node := _prop(CRYSTALS[k], 6)
	var glow := PointLight2D.new()
	glow.name = "Luz"
	glow.texture = LIGHT
	glow.color = CRYSTAL_COLORS[k]
	glow.energy = 0.5
	glow.texture_scale = 0.3
	glow.position = Vector2(0, -6)
	node.add_child(glow)
	return node


# ------------------------------------------------------------------ Mirador

## Del otro lado de la montaña: un balcón sobre el valle con las ruinas del Mural al norte.
func _lookout() -> Node2D:
	var root := _base("Mirador", HIGH, Color(1, 0.94, 0.86))
	var ground: TileMapLayer = root.get_node("Suelo")
	# Abajo no hay piso: el acantilado y el valle
	var edge := 21
	for c in _cells(Rect2i(0, edge, W, H - edge)):
		ground.erase_cell(c)
		(root.get_node("Detalles") as TileMapLayer).erase_cell(c)
	_road(root, HIGH, true, true, edge - 1)
	var view := Sprite2D.new()
	view.name = "Valle"
	view.texture = load(PANORAMA)
	view.centered = false
	view.position = Vector2(0, edge * T - 4)
	view.z_index = -30
	root.add_child(view)
	root.move_child(view, 0)
	var actors: Node2D = root.get_node("Actores")
	var keep: Array = []
	keep.append_array(_people(actors, {"Pluma": [Vector2(120, 200), "pluma"], "Vigia": [Vector2(240, 304), "vigia"]}))
	keep.append(_sign(actors, Vector2(248, 216), "sign"))
	keep.append(_sign(actors, Vector2(328, (edge - 1) * T - 4), "view_sign", "LetreroValle"))
	keep.append(_pickup(actors, "Pergamino", Vector2(520, 296), "pergamino_1", "pergaminos", "scroll"))
	_exit(root, "SalidaOeste", "west", ROAD, "cueva", "Este")
	_exit(root, "SalidaEste", "east", ROAD, "cima", "Oeste")
	_barrier(actors, "east", ROAD, 4, "barrier_peak")
	_borders(root, {"west": ROAD, "east": ROAD}, edge * T - 6)
	_entries(root, {"Oeste": ["west", ROAD], "Este": ["east", ROAD], "Puerta": Vector2(288, 136)})
	var zones: Node2D = root.get_node("Zonas")
	var look := _zone("Balcon", Rect2(304, (edge - 3) * T, 32, 2 * T))
	look.set_script(load("res://src/world/trigger_zone.gd"))
	zones.add_child(look)
	var spot := Marker2D.new()
	spot.name = "Vista"
	spot.position = Vector2(320, edge * T + 46)
	root.add_child(spot)
	var plant := func(_at: Vector2) -> Node2D:
		if _rng.randf() < 0.25:
			return _prop(BOULDER, 10)
		return (BIG if _rng.randf() < 0.5 else SMALL).instantiate()
	_scatter(actors, root, keep, plant, 4242, HIGH, edge - 2)
	return root


# ------------------------------------------------------------------ Cima

func _peak() -> Node2D:
	var root := _base("Cima", SNOW, Color(0.86, 0.9, 1.0))
	(root.get_node("Muros") as TileMapLayer).modulate = Color(0.9, 0.95, 1.1)
	_road(root, SNOW, true, false)
	var actors: Node2D = root.get_node("Actores")
	var keep: Array = []
	keep.append_array(_people(actors, {"Eco": [Vector2(104, 216), "eco"]}))
	keep.append(_sign(actors, Vector2(248, 216), "sign"))
	_exit(root, "SalidaOeste", "west", ROAD, "mirador", "Este")
	_borders(root, {"west": ROAD})
	_entries(root, {"Oeste": ["west", ROAD], "Puerta": Vector2(288, 136)})
	var pine := func(_at: Vector2) -> Node2D:
		var r := _rng.randf()
		if r < 0.55:
			return _prop(PINE_BIG, 8)
		if r < 0.8:
			return _prop(PINE, 6)
		return _prop(BOULDER_SMALL, 5)
	_scatter(actors, root, keep, pine, 777, SNOW)
	_snowfall(root)
	return root


func _snowfall(root: Node2D) -> void:
	var snow := CPUParticles2D.new()
	snow.name = "Nieve"
	snow.amount = 90
	snow.lifetime = 9.0
	snow.preprocess = 9.0
	snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow.emission_rect_extents = Vector2(W * T / 2.0, 4)
	snow.position = Vector2(W * T / 2.0, -10)
	snow.direction = Vector2(0.3, 1)
	snow.spread = 15.0
	snow.gravity = Vector2(4, 12)
	snow.initial_velocity_min = 18.0
	snow.initial_velocity_max = 30.0
	snow.scale_amount_min = 1.0
	snow.scale_amount_max = 2.0
	snow.color = Color(1, 1, 1, 0.85)
	root.get_node("Efectos").add_child(snow)


# ------------------------------------------------------------------ piezas comunes

## Mapa vacío con la fachada de ruinas del pueblo arriba.
func _base(map_name: String, kit: Dictionary, mood: Color) -> Node2D:
	_rng.seed = hash(map_name)
	var root := Node2D.new()
	root.name = map_name
	root.set_script(load("res://src/world/hub_level.gd"))
	root.set("music_key", "town")
	root.set("bounds", Rect2i(0, 0, W, H))
	root.set("spawn_facing", Vector2.UP)
	var ground: TileMapLayer = _town.get_node("Suelo").duplicate()
	var detail: TileMapLayer = _town.get_node("Detalles").duplicate()
	root.add_child(ground)
	root.add_child(detail)
	root.add_child(_town.get_node("Muros").duplicate())
	# Piso nuevo debajo de la fachada; la plaza del pueblo solo queda en el bosque
	var top := 6 if kit == GRASS else 0
	for c in _cells(Rect2i(0, top, W, H - top)):
		if (_town.get_node("Muros") as TileMapLayer).get_cell_source_id(c) >= 0 and c.y < 6:
			continue
		ground.set_cell(c, 0, kit.fill)
		detail.erase_cell(c)
		if _rng.randf() < 0.07:
			detail.set_cell(c, 0, kit.fill + Vector2i(1 + _rng.randi() % 4, 0))
	var actors := _node(root, "Actores")
	actors.y_sort_enabled = true
	_node(root, "Efectos").z_index = 20
	var zones := _node(root, "Zonas")
	var entrance: Node = _town.get_node("Zonas/EntradaTemplo").duplicate()
	entrance.name = "EntradaRuinas"
	zones.add_child(entrance)
	var shade := CanvasModulate.new()
	shade.name = "Ambiente"
	shade.color = mood
	root.add_child(shade)
	var start := Marker2D.new()
	start.name = "Inicio"
	start.position = Vector2(48, ROAD * T + T)
	root.add_child(start)
	return root


## Camino del oeste al este y subida hasta la puerta de las ruinas.
func _road(root: Node2D, kit: Dictionary, west: bool, east: bool, bottom := -1) -> void:
	var ground: TileMapLayer = root.get_node("Suelo")
	var cells: Array = []
	var from := 0 if west else 17
	var to := W if east else 19
	cells.append_array(_cells(Rect2i(from, ROAD, to - from, 2)))
	cells.append_array(_cells(Rect2i(17, 6, 2, ROAD - 6)))
	if bottom > 0:
		cells.append_array(_cells(Rect2i(19, ROAD, 2, bottom - ROAD)))
	# Plaza frente a la puerta
	cells.append_array(_cells(Rect2i(15, 6, 6, 3)))
	for c in cells:
		ground.set_cell(c, 0, kit.blob + Vector2i(1, 1))
		(root.get_node("Detalles") as TileMapLayer).erase_cell(c)
	_repaint(ground, kit, Rect2i(0, 6, W, H - 6))


## Arregla los bordes de las manchas de tierra en area.
func _repaint(ground: TileMapLayer, kit: Dictionary, area: Rect2i) -> void:
	var o: Vector2i = kit.blob
	var dirt := func(c: Vector2i) -> bool:
		if c.x < 0 or c.x >= W:
			return ground.get_cell_source_id(Vector2i(clampi(c.x, 0, W - 1), c.y)) == 0 and _is_dirt(ground, kit, Vector2i(clampi(c.x, 0, W - 1), c.y))
		return _is_dirt(ground, kit, c)
	var todo: Array = []
	for c in _cells(area):
		if dirt.call(c):
			todo.append(c)
	for c in todo:
		var n: bool = dirt.call(c + Vector2i.UP)
		var s: bool = dirt.call(c + Vector2i.DOWN)
		var w: bool = dirt.call(c + Vector2i.LEFT)
		var e: bool = dirt.call(c + Vector2i.RIGHT)
		var t := Vector2i(1, 1)
		if not n:
			t.y = 0
		elif not s:
			t.y = 2
		if not w:
			t.x = 0
		elif not e:
			t.x = 2
		if t == Vector2i(1, 1):
			if not dirt.call(c + Vector2i(1, 1)):
				t = Vector2i(5, 1)
			elif not dirt.call(c + Vector2i(-1, 1)):
				t = Vector2i(6, 1)
			elif not dirt.call(c + Vector2i(1, -1)):
				t = Vector2i(5, 2)
			elif not dirt.call(c + Vector2i(-1, -1)):
				t = Vector2i(6, 2)
		ground.set_cell(c, 0, o + t)


## Baldosa de camino (la mancha 3×3 y sus esquinas), no el pasto.
static func _is_dirt(ground: TileMapLayer, kit: Dictionary, c: Vector2i) -> bool:
	if ground.get_cell_source_id(c) != 0:
		return false
	var a := ground.get_cell_atlas_coords(c) - Vector2i(kit.blob)
	return a.y >= 0 and a.y <= 3 and a.x >= 0 and a.x <= 10


func _people(actors: Node2D, people: Dictionary) -> Array:
	var out: Array = []
	for n in people:
		var npc: Node2D = load("res://scenes/personajes/%s.tscn" % people[n][1]).instantiate()
		npc.name = n
		npc.position = people[n][0]
		actors.add_child(npc)
		out.append(people[n][0])
	return out


func _sign(actors: Node2D, at: Vector2, key: String, sign_name := "Letrero") -> Vector2:
	var sign: Node2D = SIGN.instantiate()
	sign.name = sign_name
	sign.position = at
	sign.set("lines_key", key)
	actors.add_child(sign)
	return at


func _pickup(actors: Node2D, item_name: String, at: Vector2, id: String, quest: String, look: String) -> Vector2:
	var item: Node2D = ITEM.instantiate()
	item.name = item_name
	item.position = at
	item.set("item_id", id)
	item.set("quest_id", quest)
	item.set("look", look)
	actors.add_child(item)
	return at


## Decorado con choque en la base.
func _prop(region: Rect2, foot: float) -> Node2D:
	var node := Node2D.new()
	var tex := AtlasTexture.new()
	tex.atlas = NATURE
	tex.region = region
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = tex
	sprite.position = Vector2(0, -region.size.y / 2.0 + 3)
	node.add_child(sprite)
	var body := StaticBody2D.new()
	body.name = "Cuerpo"
	var shape := CollisionShape2D.new()
	shape.name = "Forma"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(minf(region.size.x - 6, 26), foot)
	shape.shape = rect
	shape.position = Vector2(0, -foot / 2.0)
	body.add_child(shape)
	node.add_child(body)
	return node


## Llena el mapa de decorado, menos el camino, la plaza y lo que hay que ver.
func _scatter(actors: Node2D, root: Node2D, keep: Array, make: Callable, seed_value: int, kit: Dictionary, last_row := H - 1) -> void:
	_rng.seed = seed_value
	var ground: TileMapLayer = root.get_node("Suelo")
	var count := 0
	for y in range(120, last_row * T, 30):
		for x in range(16, W * T - 8, 30):
			var at := Vector2(x + _rng.randi_range(-6, 6), y + _rng.randi_range(-6, 6))
			var near_road := false
			for dx in [-20, 0, 20]:
				for dy in [-12, 0, 14]:
					if _is_dirt(ground, kit, Vector2i((at + Vector2(dx, dy)) / T)):
						near_road = true
			if near_road or at.y < 140 and absf(at.x - 288) < 70:
				continue
			if keep.any(func(p): return at.distance_to(p) < 40.0):
				continue
			if _rng.randf() < 0.35 and x > 40 and x < W * T - 40:
				continue
			var thing: Node2D = make.call(at)
			count += 1
			thing.name = "Decorado%d" % count
			thing.position = at
			actors.add_child(thing)


## Rocas que tapan una salida.
func _barrier(actors: Node2D, side: String, row: int, need: int, key: String) -> void:
	var rocks: Node2D = ROCKS.instantiate()
	rocks.name = "Rocas%d" % need
	rocks.position = _side_point(side, row, 18.0)
	rocks.set("need", need)
	rocks.set("text_key", key)
	actors.add_child(rocks)


## Bordes del mapa con huecos donde están las salidas.
func _borders(root: Node2D, gaps: Dictionary, bottom := H * T) -> void:
	var edges := _node(root, "Bordes")
	var spans := {
		"west": [Rect2(-16, 0, 16, H * T), "y"], "east": [Rect2(W * T, 0, 16, H * T), "y"],
		"south": [Rect2(0, bottom, W * T, 16), "x"],
	}
	for side in spans:
		var full: Rect2 = spans[side][0]
		var parts: Array = [full]
		if gaps.has(side):
			var g: float = gaps[side] * T
			if spans[side][1] == "y":
				parts = [Rect2(full.position, Vector2(full.size.x, g)), Rect2(full.position.x, g + 2 * T, full.size.x, full.size.y - g - 2 * T)]
		for i in parts.size():
			var body := StaticBody2D.new()
			body.name = "Borde_%s_%d" % [side, i]
			var shape := CollisionShape2D.new()
			shape.name = "Forma"
			var rect := RectangleShape2D.new()
			rect.size = parts[i].size
			shape.shape = rect
			shape.position = parts[i].get_center()
			body.add_child(shape)
			edges.add_child(body)


func _exit(root: Node2D, exit_name: String, side: String, row: int, target: String, entry: String) -> void:
	var zones: Node2D = root.get_node("Zonas") if root.has_node("Zonas") else _node(root, "Zonas")
	var at := _side_point(side, row, 4.0)
	var exit := _zone(exit_name, Rect2(at - Vector2(4, T), Vector2(8, 2 * T)))
	exit.set_script(load("res://src/world/map_exit.gd"))
	exit.set("target", target)
	exit.set("entry", entry)
	zones.add_child(exit)


func _zone(zone_name: String, rect: Rect2) -> Area2D:
	var zone := Area2D.new()
	zone.name = zone_name
	zone.position = rect.get_center()
	zone.collision_layer = 0
	var shape := CollisionShape2D.new()
	shape.name = "Forma"
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	zone.add_child(shape)
	return zone


## Marcadores donde aparece Tala al llegar.
func _entries(root: Node2D, points: Dictionary) -> void:
	var group := _node(root, "Entradas")
	for n in points:
		var mark := Marker2D.new()
		mark.name = n
		var facing := Vector2.DOWN
		if points[n] is Array:
			mark.position = _side_point(points[n][0], points[n][1], 44.0)
			facing = Vector2.RIGHT if points[n][0] == "west" else Vector2.LEFT
		else:
			mark.position = points[n]
		mark.set_meta("facing", facing)
		group.add_child(mark)


## Punto en el centro del camino, a inset píxeles del borde.
func _side_point(side: String, row: int, inset: float) -> Vector2:
	var y := row * T + T
	return Vector2(inset, y) if side == "west" else Vector2(W * T - inset, y)


static func _cells(r: Rect2i) -> Array:
	var out: Array = []
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			out.append(Vector2i(x, y))
	return out


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


func _save(root: Node2D, path: String) -> void:
	_own(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	print(path.get_file(), " -> ", error_string(ResourceSaver.save(packed, path)))
	root.free()
