module yeti16.assembler.lexer;

import std.conv;
import std.string;
import std.algorithm;

enum TokenType {
	Null,
	Identifier,
	Integer,
	String,
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
	size_t  line, tokLine, endLine;
	size_t  col,  tokCol,  endCol;
	string  reading;
	string  code;
	bool    inString;

	this() {

	}

	void AddToken(TokenType type) {
		tokens  ~= Token(type, reading, file, tokLine, tokCol);
		reading  = "";
	}

	void AddEnd() {
		tokens ~= Token(TokenType.End, "", file, endLine, endCol);
		reading  = "";
	}

	void AddReading() {
		if (reading.isNumeric()) {
			AddToken(TokenType.Integer);
		}
		else if (reading.startsWith("0x")) {
			reading = reading[2 .. $].to!long(16).text();
			AddToken(TokenType.Integer);
		}
		else if (reading.startsWith("0b")) {
			reading = reading[2 .. $].to!long(2).text();
			AddToken(TokenType.Integer);
		}
		else {
			AddToken(TokenType.Identifier);
		}
	}

	void SaveTokenLocation() {
		tokLine = line;
		tokCol  = col;
	}

	void Lex() {
		SaveTokenLocation();
		for (i = 0; i < code.length; ++ i) {
			if (code[i] == '\n') {
				endLine = line;
				endCol  = col;

				++ line;
				col = 0;
			}
			else {
				++ col;
			}

			if (inString) {
				switch (code[i]) {
					case '"': {
						inString = false;
						AddToken(TokenType.String);
						break;
					}
					default: reading ~= code[i];
				}
			}
			else {
				switch (code[i]) {
					case ',':
					case ' ':
					case '\t':
					case '\n': {
						if (reading.strip() == "") {
							reading = "";
						}
						else {
							AddReading();
						}

						if (code[i] == '\n') {
							if (
								(tokens.length > 0) &&
								(tokens[$ - 1].type == TokenType.End)
							) {
								break;
							}
							AddEnd();
						}
						break;
					}
					case '"': {
						SaveTokenLocation();
						inString = true;
						break;
					}
					case '\r': continue;
					case ':': {
						AddToken(TokenType.Label);

						endLine = line;
						endCol  = col;
						AddEnd();
						break;
					}
					case ';': {
						if (reading.strip() != "") {
							AddReading();
						}

						while (code[i] != '\n') {
							++ i;
							++ col;
							if (i >= code.length) break;
						}

						endLine = line;
						endCol  = col;

						++ line;
						col = 0;

						AddEnd();
						break;
					}
					default: {
						if (reading == "") {
							SaveTokenLocation();
						}

						reading ~= code[i];
					}
				}
			}
		}

		if ((tokens.length == 0) || (tokens[$ - 1].type != TokenType.End)) {
			AddEnd();
		}
	}
}
