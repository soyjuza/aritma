// Servidor de salas de Paredes Vivas 2D.
// El admin crea una sala (código de 5 letras), elige la configuración e inicia la partida.
// Cada jugador juega en su computador y manda su estado; el servidor arma el tablero
// y reenvía las posiciones a quien esté mirando a ese jugador.
// Mensajes: JSON con el campo "t" (tipo). Ver README.md.

const http = require("http");
const crypto = require("crypto");
const { WebSocketServer } = require("ws");

const PORT = Number(process.env.PORT || 8080);
const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const BOARD_EVERY_MS = 500;
const ROOM_IDLE_MS = 10 * 60 * 1000; // sala sin admin: se borra a los 10 minutos
const MAX_MESSAGE = 4096;

// Lo que el admin puede cambiar: [mínimo, máximo, valor inicial]
const CONFIG_LIMITS = {
  time_min: [3, 60, 15],
  hearts: [1, 10, 5],
  fall_penalty: [0, 30, 7],
  death_penalty: [0, 180, 60],
  max_players: [1, 60, 30],
};
const CONFIG_FLAGS = {
  same_exercises: false, // todos con los mismos ejercicios
  spectate: true,        // al terminar se puede ver a los demás
  skip_town: false,      // empezar directo en el templo
};

const rooms = new Map();

function defaultConfig() {
  const out = {};
  for (const [key, [, , value]] of Object.entries(CONFIG_LIMITS)) out[key] = value;
  return { ...out, ...CONFIG_FLAGS };
}

function cleanConfig(raw, current) {
  const out = { ...current };
  if (!raw || typeof raw !== "object") return out;
  for (const [key, [low, high]] of Object.entries(CONFIG_LIMITS)) {
    if (Number.isFinite(Number(raw[key]))) out[key] = Math.min(high, Math.max(low, Math.round(Number(raw[key]))));
  }
  for (const key of Object.keys(CONFIG_FLAGS)) {
    if (typeof raw[key] === "boolean") out[key] = raw[key];
  }
  return out;
}

function newCode() {
  let code;
  do {
    code = "";
    for (let i = 0; i < 5; i++) code += CODE_CHARS[crypto.randomInt(CODE_CHARS.length)];
  } while (rooms.has(code));
  return code;
}

const newToken = () => crypto.randomBytes(12).toString("hex");
const newSeed = () => crypto.randomInt(1, 2147483646);

function send(ws, msg) {
  if (ws && ws.readyState === ws.OPEN) ws.send(JSON.stringify(msg));
}

function cleanName(raw) {
  return String(raw || "").replace(/[^\p{L}\p{N} _.-]/gu, "").trim().slice(0, 16);
}

// ------------------------------------------------------------------ tablero

function playerView(p) {
  const s = p.state || {};
  return {
    id: p.id,
    name: p.name,
    status: p.status,
    online: !!(p.ws && p.ws.readyState === p.ws.OPEN),
    chamber: Number.isFinite(s.c) ? s.c : -1,
    hearts: Number.isFinite(s.h) ? s.h : 0,
    max_hearts: Number.isFinite(s.mh) ? s.mh : 0,
    time_left: Number.isFinite(s.tl) ? s.tl : 0,
    used: p.result ? p.result.used : 0,
    seed: p.seed,
  };
}

// Primero los que ganaron (menos tiempo), después los que llegaron más lejos.
function ranking(room) {
  return [...room.players.values()].map(playerView).sort((a, b) => {
    const wonA = a.status === "won";
    const wonB = b.status === "won";
    if (wonA !== wonB) return wonA ? -1 : 1;
    if (wonA) return a.used - b.used;
    if (a.chamber !== b.chamber) return b.chamber - a.chamber;
    return b.time_left - a.time_left;
  });
}

function lobbyMessage(room) {
  return { t: "lobby", code: room.code, phase: room.phase, paused: room.paused, config: room.config, players: ranking(room) };
}

function everyone(room) {
  const list = [...room.players.values()].map((p) => p.ws);
  if (room.admin) list.push(room.admin);
  return list;
}

function broadcast(room, msg) {
  for (const ws of everyone(room)) send(ws, msg);
}

function pushLobby(room) {
  broadcast(room, lobbyMessage(room));
}

// ------------------------------------------------------------------ acciones

const handlers = {
  create(ws, msg) {
    const code = newCode();
    const room = {
      code,
      admin: ws,
      adminToken: newToken(),
      config: cleanConfig(msg.config, defaultConfig()),
      phase: "lobby",
      paused: false,
      players: new Map(),
      nextId: 1,
      idleSince: 0,
    };
    rooms.set(code, room);
    ws.meta = { code, role: "admin" };
    send(ws, { t: "created", code, token: room.adminToken, config: room.config });
    pushLobby(room);
  },

  join(ws, msg) {
    const room = rooms.get(String(msg.code || "").toUpperCase().trim());
    if (!room) return send(ws, { t: "error", key: "net_err_no_room" });
    const name = cleanName(msg.name);
    if (!name) return send(ws, { t: "error", key: "net_err_name" });
    if (room.phase !== "lobby") return send(ws, { t: "error", key: "net_err_running" });
    const active = [...room.players.values()].filter((p) => p.status !== "left");
    if (active.length >= room.config.max_players) return send(ws, { t: "error", key: "net_err_full" });
    if (active.some((p) => p.name.toLowerCase() === name.toLowerCase())) return send(ws, { t: "error", key: "net_err_name_taken" });
    const p = { id: String(room.nextId++), name, ws, token: newToken(), status: "lobby", seed: 0, state: null, result: null };
    room.players.set(p.id, p);
    ws.meta = { code: room.code, role: "player", id: p.id };
    send(ws, { t: "joined", code: room.code, id: p.id, name, token: p.token, config: room.config });
    pushLobby(room);
  },

  // Vuelve a entrar tras perder la conexión (mismo juego, mismo puesto).
  resume(ws, msg) {
    const room = rooms.get(String(msg.code || "").toUpperCase());
    if (!room) return send(ws, { t: "error", key: "net_err_no_room" });
    if (msg.token === room.adminToken) {
      room.admin = ws;
      room.idleSince = 0;
      ws.meta = { code: room.code, role: "admin" };
      send(ws, { t: "created", code: room.code, token: room.adminToken, config: room.config, resumed: true });
      return pushLobby(room);
    }
    const p = [...room.players.values()].find((x) => x.token === msg.token);
    if (!p) return send(ws, { t: "error", key: "net_err_no_room" });
    if (p.ws && p.ws !== ws) p.ws.terminate();
    p.ws = ws;
    if (p.status === "left") p.status = room.phase === "lobby" ? "lobby" : "playing";
    ws.meta = { code: room.code, role: "player", id: p.id };
    send(ws, { t: "joined", code: room.code, id: p.id, name: p.name, token: p.token, config: room.config, resumed: true });
    // Si estaba caído cuando el admin inició, nunca recibió el "start": se repite
    // (el juego lo ignora si ya estaba jugando)
    if (p.status === "playing" && room.phase === "running" && p.seed) {
      send(ws, { t: "start", seed: p.seed, config: room.config, resumed: true });
    }
    pushLobby(room);
  },

  // ---- solo el admin

  config(ws, msg, room) {
    if (!isAdmin(ws, room) || room.phase !== "lobby") return;
    room.config = cleanConfig(msg.config, room.config);
    pushLobby(room);
  },

  start(ws, msg, room) {
    if (!isAdmin(ws, room) || room.phase !== "lobby") return;
    const ready = [...room.players.values()].filter((p) => p.status === "lobby");
    if (ready.length === 0) return send(ws, { t: "error", key: "net_err_no_players" });
    room.phase = "running";
    room.paused = false;
    const shared = newSeed();
    for (const p of ready) {
      p.status = "playing";
      p.seed = room.config.same_exercises ? shared : newSeed();
      p.state = null;
      p.result = null;
      send(p.ws, { t: "start", seed: p.seed, config: room.config });
    }
    pushLobby(room);
  },

  pause(ws, msg, room) {
    if (!isAdmin(ws, room) || room.phase !== "running") return;
    room.paused = !!msg.on;
    broadcast(room, { t: "pause", on: room.paused });
    pushLobby(room);
  },

  add_time(ws, msg, room) {
    if (!isAdmin(ws, room) || room.phase !== "running") return;
    const sec = Math.max(-600, Math.min(600, Math.round(Number(msg.sec) || 0)));
    for (const p of room.players.values()) {
      if (p.status === "playing" && (!msg.id || msg.id === p.id)) send(p.ws, { t: "add_time", sec });
    }
  },

  kick(ws, msg, room) {
    if (!isAdmin(ws, room)) return;
    const p = room.players.get(String(msg.id));
    if (!p) return;
    send(p.ws, { t: "kicked" });
    room.players.delete(p.id);
    // Se cierra un momento después para que el aviso alcance a llegar
    const socket = p.ws;
    if (socket) {
      socket.meta = null;
      setTimeout(() => socket.close(), 300);
    }
    pushLobby(room);
  },

  // Termina la partida: todos ven el resultado.
  end(ws, msg, room) {
    if (!isAdmin(ws, room) || room.phase !== "running") return;
    room.phase = "ended";
    room.paused = false;
    broadcast(room, { t: "ended", players: ranking(room) });
    pushLobby(room);
  },

  // Otra partida en la misma sala.
  reset(ws, msg, room) {
    if (!isAdmin(ws, room) || room.phase === "running") return;
    room.phase = "lobby";
    for (const [id, p] of room.players) {
      if (p.status === "left" && !(p.ws && p.ws.readyState === p.ws.OPEN)) room.players.delete(id);
      else Object.assign(p, { status: "lobby", state: null, result: null, seed: 0 });
    }
    broadcast(room, { t: "reset" });
    pushLobby(room);
  },

  // El admin cierra la sala: todos salen.
  close(ws, msg, room) {
    if (!isAdmin(ws, room)) return;
    for (const p of room.players.values()) send(p.ws, { t: "closed" });
    rooms.delete(room.code);
    ws.meta = null;
  },

  // ---- jugadores

  state(ws, msg, room) {
    const p = playerOf(ws, room);
    if (!p || !msg.s || typeof msg.s !== "object") return;
    p.state = msg.s;
    const snap = { t: "snap", id: p.id, s: msg.s };
    for (const other of everyone(room)) {
      if (other.meta && other.meta.watching === p.id) send(other, snap);
    }
  },

  done(ws, msg, room) {
    const p = playerOf(ws, room);
    if (!p || p.status !== "playing") return;
    p.status = msg.won ? "won" : "lost";
    p.result = { won: !!msg.won, used: Math.max(0, Number(msg.used) || 0) };
    pushLobby(room);
  },

  leave(ws, msg, room) {
    const p = playerOf(ws, room);
    if (!p) return;
    if (room.phase === "lobby") room.players.delete(p.id);
    else if (p.status === "playing") p.status = "left";
    ws.meta = null;
    pushLobby(room);
  },

  // ---- todos

  watch(ws, msg, room) {
    if (!room || !ws.meta) return;
    if (ws.meta.role === "player") {
      const me = room.players.get(ws.meta.id);
      const finished = me && ["won", "lost", "left"].includes(me.status);
      if (!(finished || room.phase === "ended") || !room.config.spectate) return;
    }
    ws.meta.watching = msg.id ? String(msg.id) : null;
    const target = room.players.get(ws.meta.watching);
    if (target && target.state) send(ws, { t: "snap", id: target.id, s: target.state });
  },
};

function isAdmin(ws, room) {
  return room && room.admin === ws;
}

function playerOf(ws, room) {
  return room && ws.meta && ws.meta.role === "player" ? room.players.get(ws.meta.id) : null;
}

function onClose(ws) {
  const meta = ws.meta;
  if (!meta) return;
  const room = rooms.get(meta.code);
  if (!room) return;
  if (meta.role === "admin" && room.admin === ws) {
    room.admin = null;
    room.idleSince = Date.now();
    return;
  }
  const p = room.players.get(meta.id);
  if (p && p.ws === ws) {
    if (room.phase === "lobby") room.players.delete(p.id);
    pushLobby(room);
  }
}

// ------------------------------------------------------------------ arranque

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ ok: true, rooms: rooms.size }));
});

const wss = new WebSocketServer({ server, maxPayload: MAX_MESSAGE });

wss.on("connection", (ws) => {
  ws.alive = true;
  ws.on("pong", () => (ws.alive = true));
  ws.on("message", (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch {
      return;
    }
    const handler = handlers[msg && msg.t];
    if (!handler) return;
    const room = ws.meta ? rooms.get(ws.meta.code) : null;
    handler(ws, msg, room);
  });
  ws.on("close", () => onClose(ws));
});

// Tablero en vivo, latido y limpieza de salas abandonadas
setInterval(() => {
  for (const room of rooms.values()) {
    if (room.phase === "running") broadcast(room, { t: "board", paused: room.paused, players: ranking(room) });
    const nobody = [...room.players.values()].every((p) => !(p.ws && p.ws.readyState === p.ws.OPEN));
    if (!room.admin && room.idleSince && Date.now() - room.idleSince > ROOM_IDLE_MS && nobody) rooms.delete(room.code);
    else if (!room.admin && room.idleSince && Date.now() - room.idleSince > ROOM_IDLE_MS * 3) {
      broadcast(room, { t: "closed" });
      rooms.delete(room.code);
    }
  }
}, BOARD_EVERY_MS);

setInterval(() => {
  for (const ws of wss.clients) {
    if (!ws.alive) {
      ws.terminate();
      continue;
    }
    ws.alive = false;
    ws.ping();
  }
}, 20000);

server.listen(PORT, () => console.log(`Servidor de Aritma en el puerto ${PORT}`));

module.exports = { server, rooms, ranking };
