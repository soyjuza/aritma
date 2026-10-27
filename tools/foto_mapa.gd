## Saca una foto entera de un mapa. Uso: Godot --path . -s tools/foto_mapa.gd -- res://escena.tscn /ruta/foto.png
extends SceneTree


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var map: Node2D = load(args[0]).instantiate()
	var b: Rect2i = map.get("bounds")
	var view := SubViewport.new()
	view.size = b.size * 16
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	map.position = -Vector2(b.position * 16)
	map.process_mode = Node.PROCESS_MODE_DISABLED
	view.add_child(map)
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png(args[1])
	quit()
