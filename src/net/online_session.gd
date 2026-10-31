## La partida en línea: rol (admin o jugador), sala, tablero y espectador.
## Habla con el servidor por NetClient; Game escucha sus señales.
class_name OnlineSession
extends RefCounted

signal room_ready              # sala creada (admin) o unido (jugador)
signal lobby_changed
signal match_started(seed_value: int, config: Dictionary)
signal paused_changed(on: bool)
signal time_added(seconds: int)
signal match_ended
signal room_reset
signal kicked
signal failed(key: String)     # clave del texto del error
signal connection_lost

const PREFS := "user://en_linea.cfg"
const SEND_EVERY := 0.1        # posición: 10 veces por segundo
const RETRY_EVERY := 2.0

var role := ""                 # "", "admin" o "player"
var phase := ""                # "", "lobby", "running" o "ended"
var code := ""
var my_id := ""
var my_name := ""
var url := ""
var config: Dictionary = {}
var players: Array = []        # tablero: diccionarios del servidor
var paused := false
var watching := ""
var snaps: Dictionary = {}     # id -> último estado recibido
var reconnecting := false

var _net := NetClient.new()
var _token := ""
var _pending: Dictionary = {}  # se manda al abrir la conexión
var _done: Dictionary = {}     # resultado: se vuelve a mandar al reconectar
var _started := false          # ya arrancó esta partida (el servidor repite "start" al reconectar)
var _send_wait := 0.0
var _retry_wait := 0.0


func _init(default_url := "") -> void:
	url = default_url
	var file := ConfigFile.new()
	if file.load(PREFS) == OK:
		url = String(file.get_value("red", "url", url))
		my_name = String(file.get_value("red", "nombre", ""))
	_net.opened.connect(_on_opened)
	_net.closed.connect(_on_closed)
	_net.message.connect(_on_message)


func save_prefs() -> void:
	var file := ConfigFile.new()
	file.set_value("red", "url", url)
	file.set_value("red", "nombre", my_name)
	file.save(PREFS)


func active() -> bool:
	return role != ""


func is_admin() -> bool:
	return role == "admin"


func is_player() -> bool:
	return role == "player"


func connecting() -> bool:
	return _net.is_connecting() or (not _pending.is_empty() and not _net.is_open())


## Fila del tablero de este jugador.
func me() -> Dictionary:
	return player(my_id)


func player(id: String) -> Dictionary:
	for p in players:
		if String(p.get("id", "")) == id:
			return p
	return {}


# ------------------------------------------------------------------ acciones

func create_room(server_url: String) -> void:
	_open(server_url, {"t": "create"})


func join_room(server_url: String, room_code: String, player_name: String) -> void:
	my_name = player_name
	_open(server_url, {"t": "join", "code": room_code.strip_edges().to_upper(), "name": player_name})


func send_config(new_config: Dictionary) -> void:
	config = new_config
	_net.send({"t": "config", "config": new_config})


func start_match() -> void:
	_net.send({"t": "start"})


func set_paused(on: bool) -> void:
	_net.send({"t": "pause", "on": on})


func add_time(seconds: int, id := "") -> void:
	_net.send({"t": "add_time", "sec": seconds, "id": id})


func kick(id: String) -> void:
	_net.send({"t": "kick", "id": id})


func end_match() -> void:
	_net.send({"t": "end"})


func reset_room() -> void:
	_net.send({"t": "reset"})


## El admin cierra la sala para todos.
func close_room() -> void:
	_net.send({"t": "close"})
	_net.close()
	_reset()


func watch(id: String) -> void:
	watching = id
	_net.send({"t": "watch", "id": id})


## El jugador manda dónde está (Game lo llama en cada cuadro).
func report(delta: float, state: Dictionary) -> void:
	_send_wait -= delta
	if _send_wait > 0.0:
		return
	_send_wait = SEND_EVERY
	_net.send({"t": "state", "s": state})


func report_done(won: bool, used: float) -> void:
	# Si la red está caída se pierde: por eso se guarda y se repite al reconectar
	_done = {"t": "done", "won": won, "used": used}
	_net.send(_done)


## Sale de la sala y cierra la conexión.
func leave() -> void:
	if is_player():
		_net.send({"t": "leave"})
	_net.close()
	_reset()


func poll(delta: float) -> void:
	_net.poll()
	if reconnecting and not _net.is_open() and not _net.is_connecting():
		_retry_wait -= delta
		if _retry_wait <= 0.0:
			_retry_wait = RETRY_EVERY
			_open(url, {"t": "resume", "code": code, "token": _token})


# ------------------------------------------------------------------ conexión

func _open(server_url: String, first: Dictionary) -> void:
	if first.t != "resume":
		_net.close()
		_reset()
	url = server_url.strip_edges()
	_pending = first
	if _net.open(url) != OK:
		_pending = {}
		failed.emit("net_err_url")


func _on_opened() -> void:
	reconnecting = false
	if not _pending.is_empty():
		_net.send(_pending)
		_pending = {}


func _on_closed() -> void:
	if not _pending.is_empty() and not reconnecting:
		_pending = {}
		failed.emit("net_err_connect")
		return
	if active() and not reconnecting:
		# Se cayó la red: se reintenta con la misma clave
		reconnecting = true
		_retry_wait = RETRY_EVERY
		connection_lost.emit()


func _reset() -> void:
	role = ""
	phase = ""
	code = ""
	my_id = ""
	_token = ""
	players = []
	snaps = {}
	watching = ""
	paused = false
	reconnecting = false
	_pending = {}
	_done = {}
	_started = false


func _on_message(msg: Dictionary) -> void:
	match String(msg.t):
		"created":
			var first := not active()
			role = "admin"
			code = String(msg.code)
			_token = String(msg.token)
			config = msg.get("config", {})
			if first:
				phase = "lobby"
				room_ready.emit()
			elif watching != "":
				watch(watching)
		"joined":
			var first := not active()
			role = "player"
			code = String(msg.code)
			my_id = String(msg.id)
			my_name = String(msg.name)
			_token = String(msg.token)
			config = msg.get("config", {})
			save_prefs()
			if first:
				phase = "lobby"
				room_ready.emit()
				return
			# Reconectado: el servidor ignora el resultado si ya lo tenía
			if not _done.is_empty():
				_net.send(_done)
			if watching != "":
				watch(watching)
		"lobby":
			phase = String(msg.get("phase", phase))
			config = msg.get("config", config)
			paused = bool(msg.get("paused", false))
			players = msg.get("players", [])
			lobby_changed.emit()
		"board":
			paused = bool(msg.get("paused", false))
			players = msg.get("players", players)
		"start":
			if _started:
				return
			_started = true
			phase = "running"
			config = msg.get("config", config)
			paused = false
			match_started.emit(int(msg.seed), config)
		"pause":
			paused = bool(msg.on)
			paused_changed.emit(paused)
		"add_time":
			time_added.emit(int(msg.sec))
		"snap":
			snaps[String(msg.id)] = msg.get("s", {})
		"ended":
			phase = "ended"
			paused = false
			players = msg.get("players", players)
			match_ended.emit()
		"reset":
			phase = "lobby"
			snaps = {}
			watching = ""
			_done = {}
			_started = false
			room_reset.emit()
		"kicked":
			_net.close()
			_reset()
			kicked.emit()
		"closed":
			_net.close()
			_reset()
			failed.emit("net_err_closed")
		"error":
			var key := String(msg.get("key", "net_err_connect"))
			# Sin sala (o la sala ya no existe al reconectar): se cierra todo
			if reconnecting or not active():
				_net.close()
				_reset()
			failed.emit(key)
