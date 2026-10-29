#!/usr/bin/env python3
"""Genera docs/UML_COMPLETO.md con todas las clases de src/, un diagrama por carpeta.
Uso: python3 tools/generar_uml.py"""
import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SRC = RAIZ / "src"
SALIDA = RAIZ / "docs" / "UML_COMPLETO.md"

CARPETAS = {
    "core": "Servicios del juego (datos, eventos, reloj, vidas, guardado)",
    "player": "Tala y sus estados (patrón State)",
    "enemies": "Guardianes, jefe, sus estados (State) y ataques (Strategy)",
    "chambers": "Salas, máquinas, fábricas (Factory Method), órdenes (Command) y problemas del jefe (Strategy)",
    "sql_lang": "El SQL del Códice: lexer, parser, motor y comparador (Interpreter, Facade)",
    "states": "Pantallas del juego (patrón State)",
    "ui": "Interfaz",
    "world": "Piezas de los mapas",
    "observers": "Observadores (patrón Observer)",
    "quality": "Calidad de efectos (patrón Strategy)",
    "camera": "Cámara",
    "fx": "Efectos",
    "tests": "Pruebas automáticas",
}


def leer(path: Path) -> dict | None:
    texto = path.read_text(encoding="utf-8")
    nombre = re.search(r"^class_name\s+(\w+)", texto, re.M)
    if not nombre:
        return None
    base = re.search(r"^extends\s+(\w+)", texto, re.M)
    patron = re.search(r"^## .*?Patrón ([\w ]+?):", texto, re.M)
    metodos = []
    for m in re.finditer(r"^(static )?func ([a-z]\w*)\(([^)]*)\)(?:\s*->\s*([\w\[\]]+))?", texto, re.M):
        estatico, nombre_m, params, retorno = m.groups()
        params = ", ".join(p.split(":")[0].split("=")[0].strip() for p in params.split(",") if p.strip())
        firma = f"+{nombre_m}({params})"
        if retorno and retorno != "void":
            firma += " " + retorno.replace("[", "~").replace("]", "~")
        if estatico:
            firma += "$"
        metodos.append(firma)
    return {
        "nombre": nombre.group(1),
        "base": base.group(1) if base else "RefCounted",
        "patron": patron.group(1).strip() if patron else "",
        "metodos": metodos,
        "archivo": path.relative_to(RAIZ).as_posix(),
    }


def main() -> None:
    clases = {}
    for path in sorted(SRC.rglob("*.gd")):
        info = leer(path)
        if info:
            carpeta = path.relative_to(SRC).parts[0] if len(path.relative_to(SRC).parts) > 1 else "raíz"
            clases.setdefault(carpeta, []).append(info)
    propias = {c["nombre"] for grupo in clases.values() for c in grupo}
    total = sum(len(g) for g in clases.values())

    out = ["# UML completo (generado)", "",
           f"Generado por `tools/generar_uml.py` a partir del código: **{total} clases**, un diagrama",
           "por carpeta de `src/`. Las flechas `<|--` son herencia. Las relaciones entre paquetes",
           "(composición, uso, eventos) están en el diagrama principal de `docs/ARQUITECTURA.md`.",
           "Para actualizarlo: `python3 tools/generar_uml.py`.", ""]
    orden = ["raíz"] + [c for c in CARPETAS if c in clases]
    for carpeta in orden:
        if carpeta not in clases:
            continue
        titulo = "Raíz (Game)" if carpeta == "raíz" else f"`src/{carpeta}/` — {CARPETAS[carpeta]}"
        out += [f"## {titulo}", "", "```mermaid", "classDiagram"]
        for c in clases[carpeta]:
            out.append(f"    class {c['nombre']} {{")
            # La etiqueta es el patrón; si no tiene, la clase de Godot de la que hereda
            etiqueta = c["patron"] or ("" if c["base"] in propias else c["base"])
            if etiqueta:
                out.append(f"        <<{etiqueta}>>")
            for m in c["metodos"]:
                out.append(f"        {m}")
            out.append("    }")
        for c in clases[carpeta]:
            if c["base"] in propias:
                out.append(f"    {c['base']} <|-- {c['nombre']}")
        out += ["```", "", "| Clase | Hereda de | Archivo |", "|---|---|---|"]
        for c in clases[carpeta]:
            out.append(f"| `{c['nombre']}` | `{c['base']}` | `{c['archivo']}` |")
        out.append("")
    SALIDA.write_text("\n".join(out), encoding="utf-8")
    print(f"{SALIDA.relative_to(RAIZ)}: {total} clases")


if __name__ == "__main__":
    main()
