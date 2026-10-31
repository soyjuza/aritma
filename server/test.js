// Pruebas del servidor: npm test (abre el servidor en un puerto libre y juega una partida).
process.env.PORT = process.env.PORT || "18080";
const assert = require("assert");
const WebSocket = require("ws");
const { server } = require("./server");

const URL = `ws://127.0.0.1:${process.env.PORT}`;
let failures = 0;

function check(ok, label) {
  console.log((ok ? "  ok   " : "  FALLO ") + label);
  if (!ok) failures++;
}

// Cliente que guarda lo que recibe y espera mensajes por tipo.
function client() {
  return new Promise((resolve) => {
    const ws = new WebSocket(URL);
    ws.inbox = [];
    ws.waiters = [];
    ws.on("message", (raw) => {
      const msg = JSON.parse(raw.toString());
      const i = ws.waiters.findIndex((w) => w.type === msg.t);
      if (i >= 0) ws.waiters.splice(i, 1)[0].resolve(msg);
      else ws.inbox.push(msg);
    });
    ws.say = (msg) => ws.send(JSON.stringify(msg));
    ws.next = (type, ms = 2000) => {
      const i = ws.inbox.findIndex((m) => m.t === type);
      if (i >= 0) return Promise.resolve(ws.inbox.splice(i, 1)[0]);
      return new Promise((res, rej) => {
        const waiter = { type, resolve: (m) => (clearTimeout(timer), res(m)) };
        const timer = setTimeout(() => {
          ws.waiters.splice(ws.waiters.indexOf(waiter), 1);
          rej(new Error("sin mensaje " + type));
        }, ms);
        ws.waiters.push(waiter);
      });
    };
    ws.drain = () => (ws.inbox = []);
    ws.on("open", () => resolve(ws));
  });
}

const wait = (ms) => new Promise((r) => setTimeout(r, ms));

async function main() {
  const admin = await client();
  admin.say({ t: "create", config: { time_min: 99, hearts: 3 } });
  const created = await admin.next("created");
  check(/^[A-Z2-9]{5}$/.test(created.code), "Sala: el admin recibe un código de 5 letras");
  check(created.config.time_min === 60 && created.config.hearts === 3, "Config: los valores fuera de rango se recortan (99 min -> 60)");

  const ana = await client();
  ana.say({ t: "join", code: created.code.toLowerCase(), name: "Ana" });
  const joined = await ana.next("joined");
  check(joined.name === "Ana" && joined.id, "Unirse: el código sirve en minúsculas y el jugador recibe su id");

  const copy = await client();
  copy.say({ t: "join", code: created.code, name: "ana" });
  check((await copy.next("error")).key === "net_err_name_taken", "Unirse: no se repite un nombre en la sala");
  copy.say({ t: "join", code: "ZZZZZ", name: "Beto" });
  check((await copy.next("error")).key === "net_err_no_room", "Unirse: un código que no existe da error");
  copy.say({ t: "join", code: created.code, name: "Beto" });
  await copy.next("joined");
  const beto = copy;

  ana.say({ t: "config", config: { time_min: 5 } });
  await wait(100);
  admin.drain();
  admin.say({ t: "config", config: { time_min: 10, same_exercises: false } });
  const lobby = await admin.next("lobby");
  check(lobby.config.time_min === 10 && lobby.players.length === 2, "Config: solo el admin la cambia; la sala tiene 2 jugadores");

  admin.say({ t: "start" });
  const startA = await ana.next("start");
  const startB = await beto.next("start");
  check(startA.config.time_min === 10 && startA.seed > 0, "Inicio: cada jugador recibe la configuración y su semilla");
  check(startA.seed !== startB.seed, "Inicio: sin «mismos ejercicios», cada jugador tiene otra semilla");

  const late = await client();
  late.say({ t: "join", code: created.code, name: "Carla" });
  check((await late.next("error")).key === "net_err_running", "Unirse: con la partida empezada ya no se entra");

  ana.say({ t: "state", s: { c: 2, x: 10, y: 20, a: "walk_up", h: 8, mh: 10, tl: 500 } });
  beto.say({ t: "state", s: { c: 1, x: 0, y: 0, a: "idle_down", h: 10, mh: 10, tl: 520 } });
  await wait(50);
  admin.drain();
  const board = await admin.next("board", 1500);
  check(board.players[0].name === "Ana" && board.players[0].chamber === 2, "Tablero: va primero quien llegó más lejos");

  admin.say({ t: "watch", id: joined.id });
  await admin.next("snap");
  ana.say({ t: "state", s: { c: 3, x: 50, y: 60, a: "run_left", h: 8, mh: 10, tl: 480 } });
  const snap = await admin.next("snap");
  check(snap.id === joined.id && snap.s.x === 50, "En vivo: el admin recibe las posiciones de quien mira");

  beto.say({ t: "watch", id: joined.id });
  ana.say({ t: "state", s: { c: 3, x: 51, y: 60, a: "run_left", h: 8, mh: 10, tl: 479 } });
  let leaked = true;
  await beto.next("snap", 300).catch(() => (leaked = false));
  check(!leaked, "En vivo: quien sigue jugando no puede mirar a los demás");

  beto.say({ t: "done", won: false, used: 300 });
  await wait(50);
  beto.say({ t: "watch", id: joined.id });
  await beto.next("snap");
  check(true, "En vivo: quien perdió ya puede mirar a los demás");

  admin.say({ t: "pause", on: true });
  check((await ana.next("pause")).on === true, "Admin: la pausa llega a los jugadores");
  admin.say({ t: "add_time", sec: 60 });
  check((await ana.next("add_time")).sec === 60, "Admin: +1 minuto llega a quien está jugando");

  ana.say({ t: "done", won: true, used: 420 });
  await wait(50);
  admin.say({ t: "end" });
  const ended = await ana.next("ended");
  check(ended.players[0].name === "Ana" && ended.players[0].status === "won", "Fin: en la tabla final la ganadora va primero");

  admin.say({ t: "reset" });
  await ana.next("reset");
  admin.drain();
  admin.say({ t: "config", config: {} });
  const again = await admin.next("lobby");
  check(again.phase === "lobby" && again.players.every((p) => p.status === "lobby"), "Otra partida: la sala vuelve a la espera con los mismos jugadores");

  admin.say({ t: "kick", id: joined.id });
  await ana.next("kicked");
  check(true, "Admin: puede sacar a un jugador");

  admin.close();
  const back = await client();
  back.say({ t: "resume", code: created.code, token: created.token });
  check((await back.next("created")).resumed === true, "Admin: si se cae la conexión vuelve a su sala con su clave");

  back.say({ t: "close" });
  check((await beto.next("closed")).t === "closed", "Admin: al cerrar la sala, los jugadores reciben el aviso");

  for (const ws of [back, ana, beto, late]) ws.close();
  console.log(failures ? `SERVIDOR FALLO (${failures})` : "SERVIDOR OK");
  server.close();
  process.exit(failures ? 1 : 0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
