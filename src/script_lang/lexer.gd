## Analizador léxico del lenguaje del Códice (Python simplificado).
## Convierte el texto en fichas (números, nombres, operadores...) y, como Python, convierte
## la sangría en fichas INDENT y DEDENT para marcar dónde empieza y termina cada bloque.
class_name Lexer
extends RefCounted

const KEYWORDS := ["if", "elif", "else", "while", "for", "in", "def", "return", "break", "continue", "pass", "and", "or", "not", "True", "False", "None"]
const OPERATORS := ["**=", "//=", "**", "//", "==", "!=", "<=", ">=", "+=", "-=", "*=", "/=", "%=", "<<", ">>", "+", "-", "*", "/", "%", "<", ">", "=", "(", ")", "[", "]", ",", ":", ".", "^", "&", "|", "~"]

var error := ""
var error_line := 0


class Token:
	var kind: String      # NUMBER, STRING, NAME, KEYWORD, OP, NEWLINE, INDENT, DEDENT, EOF
	var value
	var line: int

	func _init(p_kind: String, p_value, p_line: int) -> void:
		kind = p_kind
		value = p_value
		line = p_line

	func is_op(op: String) -> bool:
		return kind == "OP" and value == op

	func is_keyword(word: String) -> bool:
		return kind == "KEYWORD" and value == word


func tokenize(source: String) -> Array:
	var tokens: Array = []
	var indents: Array[int] = [0]
	var depth := 0  # paréntesis abiertos: dentro de ellos los saltos de línea no cuentan
	var lines := source.replace("\t", "    ").split("\n")
	for line_index in lines.size():
		var line_number := line_index + 1
		var text: String = lines[line_index]
		var stripped := text.strip_edges()
		if depth == 0 and (stripped == "" or stripped.begins_with("#")):
			continue
		if depth == 0:
			var indent := text.length() - text.lstrip(" ").length()
			if indent > indents[-1]:
				indents.append(indent)
				tokens.append(Token.new("INDENT", indent, line_number))
			while indent < indents[-1]:
				indents.pop_back()
				tokens.append(Token.new("DEDENT", indent, line_number))
			if indent != indents[-1]:
				return _fail("La sangría no coincide con ningún bloque anterior.", line_number)
		var i := text.length() - text.lstrip(" ").length()
		while i < text.length():
			var ch := text[i]
			if ch == " ":
				i += 1
				continue
			if ch == "#":
				break
			if ch.is_valid_int():
				var start := i
				while i < text.length() and (text[i].is_valid_int() or text[i] == "." or text[i] == "_"):
					i += 1
				var literal := text.substr(start, i - start).replace("_", "")
				tokens.append(Token.new("NUMBER", float(literal) if "." in literal else int(literal), line_number))
				continue
			if ch == "\"" or ch == "'":
				var end := text.find(ch, i + 1)
				if end < 0:
					return _fail("Falta cerrar el texto con %s." % ch, line_number)
				tokens.append(Token.new("STRING", text.substr(i + 1, end - i - 1), line_number))
				i = end + 1
				continue
			if _is_name_start(ch):
				var start := i
				while i < text.length() and (_is_name_start(text[i]) or text[i].is_valid_int()):
					i += 1
				var word := text.substr(start, i - start)
				tokens.append(Token.new("KEYWORD" if word in KEYWORDS else "NAME", word, line_number))
				continue
			var matched := ""
			for op in OPERATORS:
				if text.substr(i, op.length()) == op:
					matched = op
					break
			if matched == "":
				return _fail("No entiendo el símbolo '%s'." % ch, line_number)
			if matched in ["(", "["]:
				depth += 1
			elif matched in [")", "]"]:
				depth = maxi(0, depth - 1)
			tokens.append(Token.new("OP", matched, line_number))
			i += matched.length()
		if depth == 0:
			tokens.append(Token.new("NEWLINE", null, line_number))
	while indents.size() > 1:
		indents.pop_back()
		tokens.append(Token.new("DEDENT", 0, lines.size()))
	tokens.append(Token.new("EOF", null, lines.size()))
	return tokens


static func _is_name_start(ch: String) -> bool:
	return ch == "_" or (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or ch in "áéíóúñÁÉÍÓÚÑ"


func _fail(message: String, line: int) -> Array:
	error = message
	error_line = line
	return []
