module yeti16.assembler.parser;

import std.conv;
import std.stdio;
import std.format;
import std.algorithm;
import yeti16.util;
import yeti16.assembler.error;
import yeti16.assembler.lexer;
import yeti16.assembler.language;

enum NodeType {
	Null,
	Label,
	Instruction,
	Register,
	Integer,
	String,
	RegPair,
	Identifier,
	Define
}

class Node {
	NodeType  type;
	ErrorInfo error;

	this() {
		
	}

	override string toString() {
		return "blank";
	}
}

class LabelNode : Node {
	string name;

	this(ErrorInfo perror) {
		type  = NodeType.Label;
		error = perror;
	}

	override string toString() {
		return format("%s:", name);
	}
}

class InstructionNode : Node {
	string name;
	Node[] params;

	this(ErrorInfo perror) {
		type  = NodeType.Instruction;
		error = perror;
	}

	override string toString() {
		string ret = name ~ ' ';

		foreach (ref param ; params) {
			ret ~= param.toString() ~ ' ';
		}

		return ret;
	}
}

class RegisterNode : Node {
	string name;

	this(ErrorInfo perror) {
		type  = NodeType.Register;
		error = perror;
	}

	this(ErrorInfo perror, string pname) {
		type  = NodeType.Register;
		name  = pname;
		error = perror;
	}

	override string toString() {
		return name;
	}
}

class IntegerNode : Node {
	long value;

	this(ErrorInfo perror) {
		type  = NodeType.Integer;
		error = perror;
	}

	this(ErrorInfo perror, long pvalue) {
		type  = NodeType.Integer;
		value = pvalue;
		error = perror;
	}

	override string toString() {
		return text(value);
	}
}

class StringNode : Node {
	string value;

	this(ErrorInfo perror) {
		type  = NodeType.String;
		error = perror;
	}

	this(ErrorInfo perror, string pvalue) {
		type  = NodeType.String;
		value = pvalue;
		error = perror;
	}

	override string toString() {
		return format("\"%s\"", value);
	}
}

class RegPairNode : Node {
	string name;

	this(ErrorInfo perror) {
		type  = NodeType.RegPair;
		error = perror;
	}

	this(ErrorInfo perror, string pname) {
		type  = NodeType.RegPair;
		name  = pname;
		error = perror;
	}

	override string toString() {
		return name;
	}
}

class IdentifierNode : Node {
	string name;

	this(ErrorInfo perror, string pname = "") {
		type  = NodeType.Identifier;
		name  = pname;
		error = perror;
	}

	override string toString() {
		return name;
	}
}

class DefineNode : Node {
	string name;
	long   value;

	this(ErrorInfo perror) {
		type  = NodeType.Define;
		error = perror;
	}

	override string toString() {
		return format("define %s %d", name, value);
	}
}

class ParserError : Exception {
	this() {
		super("", "", 0);
	}
}

class Parser {
	Node[]  nodes;
	Token[] tokens;
	size_t  i;

	this() {
		
	}

	void Next() {
		++ i;
		if (i >= tokens.length) {
			ErrorBegin(ErrorInfo(tokens[i].file, tokens[i].line));
			stderr.writeln("Unexpected EOF");
			exit(1);
		}
	}

	ErrorInfo GetError() {
		return ErrorInfo(tokens[i].file, tokens[i].line);
	}

	void Error(Char, A...)(in Char[] fmt, A args) {
		ErrorBegin(GetError());
		stderr.writeln(format(fmt, args));
		throw new ParserError();
	}

	void Expect(TokenType type) {
		if (tokens[i].type != type) {
			Error("Expected %s, got %s", type, tokens[i].type);
		}
	}

	Node ParseLabel() {
		auto ret = new LabelNode(GetError());

		ret.name = tokens[i].contents;
		Next();
		Expect(TokenType.End);
		return ret;
	}

	Node ParseParameter() {
		switch (tokens[i].type) {
			case TokenType.Identifier: {
				if (Language.registers.canFind(tokens[i].contents)) {
					return new RegisterNode(GetError(), tokens[i].contents);
				}
				else if (Language.regPairs.canFind(tokens[i].contents)) {
					return new RegPairNode(GetError(), tokens[i].contents);
				}
				else {
					return new IdentifierNode(GetError(), tokens[i].contents);
				}
			}
			case TokenType.Integer: {
				return new IntegerNode(GetError(), parse!long(tokens[i].contents));
			}
			case TokenType.String: {
				return new StringNode(GetError(), tokens[i].contents);
			}
			default: {
				Error("Unexpected %s", tokens[i].contents);
				assert(0);
			}
		}
	}

	Node ParseInstruction() {
		auto ret = new InstructionNode(GetError());
		ret.name = tokens[i].contents;
		Next();

		while (tokens[i].type != TokenType.End) {
			ret.params ~= ParseParameter();
			Next();
		}
		
		return ret;
	}

	Node ParseDefine() {
		auto ret = new DefineNode(GetError());
		Next();
		Expect(TokenType.Identifier);
		ret.name = tokens[i].contents;
		Next();
		Expect(TokenType.Integer);
		ret.value = parse!long(tokens[i].contents);
		Next();
		Expect(TokenType.End);
		return ret;
	}

	Node ParseStatement() {
		switch (tokens[i].type) {
			case TokenType.Label:      return ParseLabel();
			case TokenType.Identifier: {
				switch (tokens[i].contents) {
					case "define": return ParseDefine();
					default:       return ParseInstruction();
				}
			}
			case TokenType.End: return null;
			default: {
				Error("Unexpected %s token", tokens[i].type);
				assert(0);
			}
		}
	}

	void Parse() {
		for (i = 0; i < tokens.length; ++ i) {
			auto node = ParseStatement();

			if (node) {
				nodes ~= node;
			}
		}
	}
}
