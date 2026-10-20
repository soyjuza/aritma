## Reglas de un rompecabezas de la Mesa.
## La figura sale de chambers.json: cada letra es una pieza.
class_name FigurePuzzle
extends RefCounted

const NONE := Vector2i(-99, -99)

var title := ""
var target: Dictionary = {}
var size := Vector2i.ZERO
var pieces: Array = []
var solution: Array = []


## turned: las piezas llegan giradas.
static func from_layout(layout: Array, p_title: String, turned: bool, rng: RandomNumberGenerator) -> FigurePuzzle:
	var puzzle := FigurePuzzle.new()
	puzzle.title = p_title
	var by_letter := {}
	for y in layout.size():
		var row := String(layout[y])
		puzzle.size.y = layout.size()
		puzzle.size.x = maxi(puzzle.size.x, row.length())
		for x in row.length():
			var letter := row[x]
			if letter == "." or letter == " ":
				continue
			puzzle.target[Vector2i(x, y)] = true
			if not by_letter.has(letter):
				by_letter[letter] = []
			by_letter[letter].append(Vector2i(x, y))
	var letters := by_letter.keys()
	letters.sort()
	for letter in letters:
		var cells: Array[Vector2i] = []
		cells.assign(by_letter[letter])
		puzzle.pieces.append({"cells": normalized(cells), "at": NONE})
		puzzle.solution.append({"cells": normalized(cells), "at": corner(cells)})
	if turned:
		for i in puzzle.pieces.size():
			for k in rng.randi_range(1, 3):
				puzzle.rotate(i)
	return puzzle


static func corner(cells: Array[Vector2i]) -> Vector2i:
	var low := Vector2i(1 << 20, 1 << 20)
	for c in cells:
		low = Vector2i(mini(low.x, c.x), mini(low.y, c.y))
	return low


## Corre las casillas a (0, 0).
static func normalized(cells: Array[Vector2i]) -> Array[Vector2i]:
	var low := corner(cells)
	var out: Array[Vector2i] = []
	for c in cells:
		out.append(c - low)
	return out


static func extent(cells: Array[Vector2i]) -> Vector2i:
	var high := Vector2i.ZERO
	for c in cells:
		high = Vector2i(maxi(high.x, c.x), maxi(high.y, c.y))
	return high + Vector2i.ONE


func cells_of(i: int) -> Array[Vector2i]:
	return pieces[i].cells


## Gira la pieza a la derecha.
func rotate(i: int) -> void:
	var turned: Array[Vector2i] = []
	for c in cells_of(i):
		turned.append(Vector2i(-c.y, c.x))
	pieces[i].cells = normalized(turned)


func is_placed(i: int) -> bool:
	return pieces[i].at != NONE


## Casillas ocupadas.
func occupied(except := -1) -> Dictionary:
	var out := {}
	for i in pieces.size():
		if i != except and is_placed(i):
			for c in cells_of(i):
				out[c + pieces[i].at] = i
	return out


## ¿Cabe la pieza en at?
func can_place(i: int, at: Vector2i) -> bool:
	var taken := occupied(i)
	for c in cells_of(i):
		if not target.has(c + at) or taken.has(c + at):
			return false
	return true


func place(i: int, at: Vector2i) -> bool:
	if not can_place(i, at):
		return false
	pieces[i].at = at
	return true


func lift(i: int) -> void:
	pieces[i].at = NONE


func is_solved() -> bool:
	for i in pieces.size():
		if not is_placed(i):
			return false
	return occupied().size() == target.size()
