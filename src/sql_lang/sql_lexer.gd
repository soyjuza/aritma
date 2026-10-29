## Patrón Interpreter: parte la consulta en palabras, números, textos y símbolos.
## Cada pieza es {type, text, upper, value, line}; type: word, number, text, symbol o end.
class_name SqlLexer
extends RefCounted

const PAIRS := ["<=", ">=", "<>", "!=", "==", "=>", "=<"]
const SINGLES := ["=", "<", ">", ",", ".", "*", "(", ")", ";", "+", "-", "/", "%"]
const QUOTES := ["'", "‘", "’"]    # los teclados de celular ponen comillas curvas

var error := ""
var error_line := 0


func tokenize(source: String) -> Array:
	var tokens: Array = []
	var i := 0
	var line := 1
	var n := source.length()
	while i < n:
		var c := source[i]
		if c == "\n":
			line += 1
			i += 1
		elif c == " " or c == "\t" or c == "\r":
			i += 1
		elif c == "-" and i + 1 < n and source[i + 1] == "-":
			while i < n and source[i] != "\n":
				i += 1
		elif c == "#":
			return _fail("comentario_numeral", {}, line)
		elif _is_letter(c):
			var start := i
			while i < n and (_is_letter(source[i]) or _is_digit(source[i])):
				i += 1
			var word := source.substr(start, i - start)
			tokens.append(_token("word", word, word, line))
		elif _is_digit(c):
			var start := i
			while i < n and _is_digit(source[i]):
				i += 1
			if i + 1 < n and source[i] == "." and _is_digit(source[i + 1]):
				i += 1
				while i < n and _is_digit(source[i]):
					i += 1
			var digits := source.substr(start, i - start)
			if i < n and _is_letter(source[i]):
				return _fail("numero_pegado", {"texto": digits + source[i]}, line)
			tokens.append(_token("number", digits, float(digits) if "." in digits else int(digits), line))
		elif c in QUOTES:
			var start := i + 1
			var value := ""
			i += 1
			var closed := false
			while i < n:
				if source[i] in QUOTES:
					# '' dentro de un texto es una comilla
					if i + 1 < n and source[i + 1] in QUOTES:
						value += "'"
						i += 2
						continue
					closed = true
					break
				if source[i] == "\n":
					break
				value += source[i]
				i += 1
			if not closed:
				return _fail("falta_cerrar_texto", {"texto": source.substr(start, i - start).strip_edges()}, line)
			i += 1
			tokens.append(_token("text", "'%s'" % value, value, line))
		elif c == "\"" or c == "“" or c == "”":
			var end := i + 1
			while end < n and not source[end] in ["\"", "“", "”", "\n"]:
				end += 1
			return _fail("comillas_dobles", {"texto": source.substr(i + 1, end - i - 1)}, line)
		elif i + 1 < n and source.substr(i, 2) in PAIRS:
			tokens.append(_token("symbol", source.substr(i, 2), null, line))
			i += 2
		elif c in SINGLES:
			tokens.append(_token("symbol", c, null, line))
			i += 1
		else:
			return _fail("simbolo_raro", {"simbolo": c}, line)
	tokens.append(_token("end", "", null, line))
	return tokens


func _fail(key: String, params: Dictionary, line: int) -> Array:
	error = SqlMessages.text(key, params)
	error_line = line
	return []


static func _token(type: String, text: String, value, line: int) -> Dictionary:
	return {"type": type, "text": text, "upper": text.to_upper(), "value": value, "line": line}


## Letras con tilde y ñ también cuentan.
static func _is_letter(c: String) -> bool:
	return c == "_" or c.to_lower() != c.to_upper()


static func _is_digit(c: String) -> bool:
	return c >= "0" and c <= "9"
