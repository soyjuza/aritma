## Indicadores durante el juego: objetivo, energía del núcleo (tiempo), corazones, castigos de
## tiempo, alarma de los guardianes, aliento, mira, ayuda de lo que se tiene enfrente y teclas.
## Solo dibuja; los datos se los pasa PlayState.
class_name Hud
extends RefCounted

const HEART := preload("res://assets/pack/ui/Receptacle/Heart.png")   # 5 cuadros: vacío → lleno
const HEART_SCALE := 2.0


func draw(ui: UIKit, info: Dictionary) -> void:
	var s := ui.size()
	if info.get("title", "") != "":
		ui.text(String(info.title), Vector2(28, 22), 20, UIKit.GOLD, "title")
	if info.get("objective", "") != "":
		var objective := String(info.objective)
		var w := ui.measure(objective, 19) + 60
		ui.rect(Rect2(28, 54, w, 40), Color(0.04, 0.055, 0.08, 0.78))
		ui.frame(Rect2(28, 54, w, 40), Color("2a3340"), 1.0)
		ui.diamond(Vector2(46, 74), 7, UIKit.CYAN)
		ui.text(objective, Vector2(64, 62), 19)
	if info.get("extra", "") != "":
		var extra := String(info.extra)
		var ew := ui.measure(extra, 16, "bold") + 32
		ui.rect(Rect2(28, 100, ew, 32), Color(0.04, 0.055, 0.08, 0.78))
		ui.text(extra, Vector2(44, 107), 16, UIKit.CYAN, "bold", false)
	if info.get("alarm", 0) > 0:
		draw_alarm(ui, int(info.alarm), int(info.get("guardians", 0)), String(info.get("alarm_label", "")))
	if info.get("timer_active", false):
		draw_timer(ui, info.timer)
		if info.has("health"):
			draw_hearts(ui, info.health, float(info.get("hurt", 0.0)))
		draw_penalty(ui, String(info.get("penalty", "")), float(info.get("penalty_left", 0.0)))
	# Mira
	var c := s / 2.0
	ui.rect(Rect2(c - Vector2(3, 3), Vector2(6, 6)), Color(0, 0, 0, 0.5))
	ui.rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), UIKit.TEXT)
	# Ayuda de interacción
	if info.get("prompt", "") != "":
		var key := String(info.prompt_key)
		var text := String(info.prompt)
		var kw := ui.measure(key, 20, "bold") + 18
		var w := kw + ui.measure(text, 20) + 44
		var r := Rect2((s.x - w) / 2.0, c.y + 60, w, 42)
		ui.rect(r, Color(0.04, 0.055, 0.08, 0.85))
		ui.frame(r, UIKit.GOLD, 1.5)
		ui.rect(Rect2(r.position + Vector2(10, 8), Vector2(kw, 26)), UIKit.GOLD)
		ui.text(key, r.position + Vector2(19, 10), 20, Color("0b0f14"), "bold", false)
		ui.text(text, r.position + Vector2(kw + 24, 10), 20)
	# Aliento
	var stamina: float = info.get("stamina", 1.0)
	if stamina < 0.999:
		ui.rect(Rect2(28, s.y - 78, 200, 8), Color("1f2730"))
		ui.rect(Rect2(28, s.y - 78, 200 * stamina, 8), UIKit.GOOD if stamina > 0.25 else UIKit.ALERT)
		ui.text(String(info.get("stamina_label", "")), Vector2(240, s.y - 86), 14, UIKit.MUTED)
	ui.text(String(info.get("keys", "")), Vector2(28, s.y - 52), 15, UIKit.MUTED)
	if info.get("fps", "") != "":
		ui.text_right(String(info.fps), s.x - 24, s.y - 40, 15, UIKit.MUTED)


## Aviso arriba al centro (se desvanece en el último segundo). Urgente: rojo; buena noticia
## (good): verde, más grande y con el borde latiendo.
func draw_notice(ui: UIKit, text: String, left: float, good := false) -> void:
	if text == "" or left <= 0.0:
		return
	var s := ui.size()
	var alpha := clampf(left, 0.0, 1.0)
	var size := 30 if good else 22
	var rows: Array = ui.wrap(text, minf(720.0, s.x - 520.0), size, "bold")
	var h := rows.size() * (ui.line_height(size, "bold") + 2) + 26
	var w := minf(780.0, s.x - 460.0)
	var r := Rect2((s.x - w) / 2.0, 104, w, h)
	if good:
		var pulse := 0.6 + 0.4 * sin(ui.time * 5.0)
		ui.rect(r, Color(0.02, 0.09, 0.04, 0.9 * alpha))
		ui.frame(r.grow(3), Color(UIKit.GOOD, 0.4 * pulse * alpha), 2.0)
		ui.frame(r, Color(UIKit.GOOD, alpha), 3.0)
	else:
		ui.rect(r, Color(0.09, 0.03, 0.02, 0.86 * alpha))
		ui.frame(r, Color(UIKit.ALERT, alpha), 2.0)
	var y := r.position.y + 13
	for row in rows:
		ui.text_centered(String(row), y, size, Color(UIKit.TEXT, alpha), "bold")
		y += ui.line_height(size, "bold") + 2


## Corazones bajo el reloj, en mitades (el cuadro 0 es vacío, el 2 medio y el 4 lleno).
## Si quedan pocos, el último late.
func draw_hearts(ui: UIKit, health: PlayerHealth, hurt: float) -> void:
	var s := ui.size()
	var size := 16.0 * HEART_SCALE
	var total := health.hearts()
	var x0 := s.x - 28 - total * (size + 2)
	var y := 92.0
	if hurt > 0.0:
		x0 += randf_range(-3, 3)
	for i in total:
		var halves := clampi(health.halves - i * 2, 0, 2)
		var src := Rect2(halves * 2 * 16, 0, 16, 16)
		var r := Rect2(x0 + i * (size + 2), y, size, size)
		if health.halves <= 2 and halves > 0 and ui.blink(3.0):
			r = r.grow(2)
		ui.texture_region(HEART, r, src)


## "−7 s" en rojo bajo los corazones: sube y se desvanece.
func draw_penalty(ui: UIKit, text: String, left: float) -> void:
	if text == "" or left <= 0.0:
		return
	var s := ui.size()
	var a := clampf(left / 0.8, 0.0, 1.0)
	var y := 140.0 - (2.2 - left) * 12.0
	ui.text_right(text, s.x - 28, y, 30, Color(UIKit.ALERT, a), "title")


## La alarma: los bordes laten en rojo y arriba al centro se lee el nivel y cuántos quedan.
func draw_alarm(ui: UIKit, level: int, guardians: int, label: String) -> void:
	var s := ui.size()
	var pulse := 0.5 + 0.5 * sin(ui.time * 5.0)
	ui.vignette(0.35 + 0.25 * pulse, Color(0.75, 0.05, 0.02))
	var w := ui.measure(label, 20, "bold") + 48
	var r := Rect2((s.x - w) / 2.0, 18, w, 38)
	ui.rect(r, Color(0.12, 0.02, 0.02, 0.88))
	ui.frame(r, Color(UIKit.ALERT, 0.6 + 0.4 * pulse), 2.0)
	ui.text_centered(label, r.position.y + 7, 20, UIKit.TEXT, "bold")


func draw_timer(ui: UIKit, timer: CountdownTimer) -> void:
	var s := ui.size()
	var r := Rect2(s.x - 210, 20, 182, 64)
	ui.rect(r, Color(0.04, 0.055, 0.08, 0.85))
	ui.frame(r, Color("3a2f17"), 1.5)
	var frac := timer.remaining / maxf(1.0, timer.limit)
	var center := r.position + Vector2(36, 32)
	ui.arc(center, 20, 0, TAU, Color("1f2730"), 5)
	ui.arc(center, 20, -PI / 2, -PI / 2 + TAU * frac, UIKit.CYAN if not timer.is_warning() else UIKit.ALERT, 5)
	var color := UIKit.ALERT if timer.is_warning() and ui.blink(4.0) else UIKit.TEXT
	ui.text_right(CountdownTimer.format(timer.remaining), r.end.x - 18, r.position.y + 12, 36, color, "title")
