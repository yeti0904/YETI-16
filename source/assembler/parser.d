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
	RegPair,
	Identifier
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

	this() {
		type = NodeType.Label;
	}

	override string toString() {
		return format("%s:", name);
	}
}

class InstructionNode : Node {
	string name;
	Node[] params;

	this() {
		type = NodeType.Instruction;
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

	this() {
		type = NodeType.Register;
	}

	this(string pname) {
		type = NodeType.Register;
		name = pname;
	}

	override string toString() {
		return name;
	}
}

class IntegerNode : Node {
	long value;

	this() {
		type = NodeType.Integer;
	}

	this(long pvalue) {
		type  = NodeType.Integer;
		value = pvalue;
	}

	override string toString() {
		return text(value);
	}
}

class RegPairNode : Node {
	string name;

	this() {
		type = NodeType.RegPair;
	}

	this(string pname) {
		type = NodeType.RegPair;
		name = pname;
	}

	override string toString() {
		return name;
	}
}

class IdentifierNode : Node {
	string name;

	this(string pname = "") {
		type = NodeType.Identifier;
		name = pname;
	}

	override string toString() {
		return name;
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
		auto ret = new LabelNode();

		ret.name = tokens[i].contents;
		Next();
		Expect(TokenType.End);
		return ret;
	}

	Node ParseParameter() {
		switch (tokens[i].type) {
			case TokenType.Identifier: {
				if (Language.registers.canFind(tokens[i].contents)) {
					return new RegisterNode(tokens[i].contents);
				}
				else if (Language.regPairs.canFind(tokens[i].contents)) {
					return new RegPairNode(tokens[i].contents);
				}
				else {
					return new IdentifierNode(tokens[i].contents);
				}
			}
			case TokenType.Integer: {
				return new IntegerNode(parse!long(tokens[i].contents));
			}
			default: {
				Error("Unexpected %s", tokens[i].contents);
				assert(0);
			}
		}
	}

	Node ParseInstruction() {
		auto ret = new InstructionNode();
		ret.name = tokens[i].contents;
		Next();

		while (tokens[i].type != TokenType.End) {
			ret.params ~= ParseParameter();
			Next();
		}
		
		return ret;
	}

	Node ParseStatement() {
		switch (tokens[i].type) {
			case TokenType.Label:      return ParseLabel();
			case TokenType.Identifier: return ParseInstruction();
			default: {
				Error("Unexpected %s token", tokens[i].type);
				assert(0);
			}
		}
	}

	void Parse() {
		for (i = 0; i < tokens.length; ++ i) {
			nodes ~= ParseStatement();
		}
	}
}
