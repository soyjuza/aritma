## Patrón Facade: chispas, humo y partículas sin saber cómo se arman.
class_name TileKit
extends RefCounted

const TILE := 16
const PACK := "res://assets/pack/"

const FX_FRAMES := {"Fire": 8, "Spark": 7, "Clouds": 2, "Rock": 5, "RockGray": 5, "Snow": 7, "Leaf": 6, "Grass": 6, "Wood": 6, "Smoke": 6}

var particle_scale := 1.0    # lo fija la calidad (Strategy): menos partículas en "baja"

var _textures: Dictionary = {}


func texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(PACK + path)
	return _textures[path]


func particles(parent: Node, at: Vector2, fx: String, amount := 16, lifetime := 0.8) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = at
	p.amount = maxi(2, int(amount * particle_scale))
	p.lifetime = lifetime
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.85
	p.spread = 180.0
	p.gravity = Vector2(0, 60)
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 80.0
	p.texture = texture("fx/Smoke/Smoke/SpriteSheet.png" if fx == "Smoke" else "fx/Particle/%s.png" % fx)
	if fx == "Smoke":
		p.scale_amount_min = 0.35
		p.scale_amount_max = 0.6
	var mat := CanvasItemMaterial.new()
	mat.particles_animation = true
	mat.particles_anim_h_frames = int(FX_FRAMES.get(fx, maxi(1, int(p.texture.get_width() / p.texture.get_height()))))
	mat.particles_anim_v_frames = 1
	p.material = mat
	p.anim_speed_min = 1.0
	p.anim_speed_max = 1.0
	parent.add_child(p)
	return p
