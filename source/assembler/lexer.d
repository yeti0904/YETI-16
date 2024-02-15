module yeti16.assembler.lexer;

import std.string;

enum TokenType {
	Null,
	Identifier,
	Integer,
	Label,
	End
}

struct Token {
	TokenType type;
	string    contents;
	string    file;
	size_t    line;
	size_t    col;
}

class Lexer {
	Token[] tokens;
	size_t  i;
	string  file;
	size_t  line;
	size_t  col;
	string  reading;
	string  code;

	this() {
		
	}

	void AddToken(TokenType type) {
		tokens  ~= Token(type, reading, file, line, col);
		reading  = "";
	}

	void AddBlank(TokenType type) {
		tokens ~= Token(type, "", file, line, col);
	}

	void AddReading() {
		if (reading.isNumeric()) {
			AddToken(TokenType.Integer);
		}
		else {
			AddToken(TokenType.Identifier);
		}
	}

	void Lex() {
		for (i = 0; i < code.length; ++ i) {
			if (code[i] == '\n') {
				++ line;
				col = 0;
			}
			else {
				++ col;
			}

			switch (code[i]) {
				case ',':
				case ' ':
				case '\t':
				case '\n': {
					if (reading.strip() == "") {
						reading = "";
						break;
					}
					
					AddReading();

					if (code[i] == '\n') {
						if ((tokens.length > 0) && (tokens[$ - 1].type == TokenType.End)) {
							break;
						}
						AddBlank(TokenType.End);
					}
					break;
				}
				case '\r': continue;
				case ':': {
					AddToken(TokenType.Label);
					AddToken(TokenType.End);
					break;
				}
				default: {
					reading ~= code[i];
				}
			}
		}

		if ((tokens.length == 0) || (tokens[$ - 1].type != TokenType.End)) {
			AddBlank(TokenType.End);
		}
	}
}
