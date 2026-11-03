## Enemigos, jefe y orbes de la sala del jugador, para que el espectador los vea.
## El jugador los resume en su estado (capture) y la copia del espectador los
## dibuja como títeres (apply): no piensan solos, solo lo que mandó el jugador.
class_name WorldSync
extends RefCounted

const SCENES := {
	"caballero": preload("res://scenes/enemigos/centinela.tscn"),
	"hechicero": preload("res://scenes/enemigos/hechicero.tscn"),
	"rúnico": preload("res://scenes/enemigos/runico.tscn"),
}
const ORB := preload("res://scenes/enemigos/orbe.tscn")
const JUMP := 80.0    # más lejos que esto: salta en vez de deslizarse

var _level: Level
var _guards := {}    # id -> Guardian que se está mostrando
var _orbs := {}      # id -> RuneOrb
var _boss: ZeroBoss


# ------------------------------------------------------------------ jugador

## Lo que hay vivo en la sala. Las estatuas dormidas no se mandan (ya están en la copia).
static func capture(level: Node) -> Dictionary:
	var out := {}
	if level == null or not level.is_inside_tree():
		return out
	var tree := level.get_tree()
	var guards := {}
	for g: Guardian in tree.get_nodes_in_group("guardians"):
		if g.state_name != "dormant" and not g.is_queued_for_deletion() and level.is_ancestor_of(g):
			guards[_guard_id(level, g)] = g.net_pack()
	if not guards.is_empty():
		out["g"] = guards
	var orbs := {}
	for o: RuneOrb in tree.get_nodes_in_group("orbs"):
		if not o.is_queued_for_deletion() and level.is_ancestor_of(o):
			orbs[str(o.get_instance_id())] = [roundi(o.global_position.x), roundi(o.global_position.y), o.color.to_html(false)]
	if not orbs.is_empty():
		out["o"] = orbs
	var boss := tree.get_first_node_in_group("boss") as ZeroBoss
	if boss and boss.state != "hidden" and level.is_ancestor_of(boss):
		out["b"] = boss.net_pack()
	return out


## Las estatuas son parte de la sala: se buscan por su ruta. Las que caen del techo, por su número.
static func _guard_id(level: Node, g: Guardian) -> String:
	return "i%d" % g.get_instance_id() if g.from_ceiling else String(level.get_path_to(g))


# ------------------------------------------------------------------ espectador

## Convierte los enemigos de la copia en títeres.
func _init(level: Level) -> void:
	_level = level
	for g: Guardian in level.nodes_of(Guardian):
		_make_puppet(g)
	for b: ZeroBoss in level.nodes_of(ZeroBoss):
		b.puppet = true
		_boss = b


## a y b: los dos estados entre los que va el fantasma; w: cuánto de b.
func apply(a: Dictionary, b: Dictionary, w: float) -> void:
	if not is_instance_valid(_level):
		return
	_apply_guards(a.get("g", {}), b.get("g", {}), w)
	_apply_orbs(a.get("o", {}), b.get("o", {}), w)
	if is_instance_valid(_boss):
		var near: Dictionary = (a if w < 0.5 else b).get("b", {})
		if near.is_empty():
			_boss.net_hide()
		else:
			_boss.net_apply(a.get("b", near), b.get("b", near), w)


func _apply_guards(ga: Dictionary, gb: Dictionary, w: float) -> void:
	var near := ga if w < 0.5 else gb
	for id: String in near:
		var g := _guard(id, near[id])
		if g:
			g.net_apply(ga.get(id, near[id]), gb.get(id, near[id]), w)
	for id: String in _guards.keys():
		if near.has(id):
			continue
		var g: Guardian = _guards[id]
		_guards.erase(id)
		if not is_instance_valid(g):
			continue
		if id.begins_with("i"):
			g.net_vanish()    # murió o se deshizo
		else:
			g.net_restore()   # la estatua volvió a dormir (Tala cayó)


func _guard(id: String, pack: Dictionary) -> Guardian:
	var g: Guardian = _guards.get(id)
	if is_instance_valid(g):
		return g
	if id.begins_with("i"):
		var scene: PackedScene = SCENES.get(String(pack.get("k", "")), SCENES.caballero)
		g = scene.instantiate()
		g.puppet = true
		g.setup(null, _level.kit, {})
		g.position = _level.actors.to_local(Vector2(float(pack.get("x", 0)), float(pack.get("y", 0))))
		_level.actors.add_child(g)
		_make_puppet(g)
	else:
		g = _level.get_node_or_null(NodePath(id)) as Guardian
		if g == null:
			return null
	_guards[id] = g
	return g


func _make_puppet(g: Guardian) -> void:
	g.puppet = true
	g.collision_layer = 0
	g.collision_mask = 0


func _apply_orbs(oa: Dictionary, ob: Dictionary, w: float) -> void:
	var near := oa if w < 0.5 else ob
	for id: String in near:
		var o: RuneOrb = _orbs.get(id)
		if not is_instance_valid(o):
			o = ORB.instantiate()
			o.puppet = true
			o.color = Color.html(String(near[id][2]))
			_level.actors.add_child(o)
			_orbs[id] = o
		var pa := _point(oa.get(id, near[id]))
		var pb := _point(ob.get(id, near[id]))
		o.global_position = pa.lerp(pb, w) if pa.distance_to(pb) < JUMP else _point(near[id])
	for id: String in _orbs.keys():
		if near.has(id):
			continue
		var o: RuneOrb = _orbs[id]
		_orbs.erase(id)
		if is_instance_valid(o):
			o.shatter()


static func _point(v: Array) -> Vector2:
	return Vector2(float(v[0]), float(v[1]))
