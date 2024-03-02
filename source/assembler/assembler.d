module yeti16.assembler.assembler;

import std.stdio;
import std.format;
import std.algorithm;
import yeti16.util;
import yeti16.assembler.error;
import yeti16.assembler.parser;

static import yeti16.emulator;
alias InstBin = yeti16.emulator.Instruction;

class AssemblerException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

private ubyte CompileRegister(string reg) {
	switch (reg) {
		case "a": return 0;
		case "b": return 1;
		case "c": return 2;
		case "d": return 3;
		case "e": return 4;
		case "f": return 5;
		case "g": return 6;
		case "h": return 7;
		default:  throw new AssemblerException(format("Invalid register '%s'", reg));
	}
}

private ubyte CompileRegPair(string reg) {
	switch (reg) {
		case "ab": return 0;
		case "cd": return 1;
		case "ef": return 2;
		case "gh": return 3;
		case "ip": return 4;
		case "sp": return 5;
		case "bs": return 6;
		case "ds": return 7;
		case "sr": return 8;
		default: {
			throw new AssemblerException(format("Invalid register pair '%s'", reg));
		}
	}
}

class Instruction {
	ubyte      opcode;
	NodeType[] paramTypes;

	abstract uint    Size();
	abstract ubyte[] Assemble(ErrorInfo error, Node[] params);

	final void ValidParams(ErrorInfo error, Node[] params) {
		if (params.length != paramTypes.length) {
			ErrorBegin(error);
			stderr.writefln("Expected %d parameters, got %d", paramTypes.length, params.length);
			exit(1);
		}

		foreach (i, ref node ; params) {
			if (node.type != paramTypes[i]) {
				ErrorBegin(node.error);
				stderr.writefln("Expected %s, got %s", paramTypes[i], node.type);
				exit(1);
			}
		}
	}
}

class InstNoArgs : Instruction {
	this(ubyte pop) {
		opcode = pop;
	}

	override uint Size() => 1;

	override ubyte[] Assemble(ErrorInfo error, Node[] params) {
		ValidParams(error, params);
		return [opcode];
	}
}

class Inst0RDD : Instruction {
	this(ubyte pop) {
		opcode     = pop;
		paramTypes = [NodeType.Register, NodeType.Integer];
	}

	override uint Size() => 3;

	override ubyte[] Assemble(ErrorInfo error, Node[] params) {
		ValidParams(error, params);

		auto reg = (cast(RegisterNode) params[0]).name;
		auto val = cast(ubyte) ((cast(IntegerNode)  params[1]).value & 0xFF);

		return [opcode] ~ CompileRegister(reg) ~ cast(ubyte) val;
	}
}

class Inst0RDDDD : Instruction {
	this(ubyte pop) {
		opcode     = pop;
		paramTypes = [NodeType.Register, NodeType.Integer];
	}

	override uint Size() => 4;

	override ubyte[] Assemble(ErrorInfo error, Node[] params) {
		ValidParams(error, params);

		auto reg = (cast(RegisterNode) params[0]).name;
		auto val = cast(ushort) ((cast(IntegerNode)  params[1]).value & 0xFFFF);

		return [opcode] ~ CompileRegister(reg) ~ NativeToYeti(val);
	}
}

class InstRR : Instruction {
	this(ubyte pop) {
		opcode     = pop;
		paramTypes = [NodeType.Register, NodeType.Register];
	}

	override uint Size() => 2;

	override ubyte[] Assemble(ErrorInfo error, Node[] params) {
		ValidParams(error, params);

		auto r1 = (cast(RegisterNode) params[0]).name;
		auto r2 = (cast(RegisterNode) params[1]).name;

		return [opcode] ~ (
			cast(ubyte) (CompileRegister(r1) << 4) |
			cast(ubyte) (CompileRegister(r2) & 0x0F)
		);
	}
}

class Inst0R : Instruction {
	this(ubyte pop) {
		opcode     = pop;
		paramTypes = [NodeType.Register];
	}

	override uint Size() => 2;

	override ubyte[] Assemble(ErrorInfo error, Node[] params) {
		ValidParams(error, params);

		auto reg = (cast(RegisterNode) params[0]).name;

		return [opcode] ~ CompileRegister(reg);
	}
}

class InstDD : Instruction {
	this(ubyte pop) {
		opcode     = pop;
		paramTypes = [NodeType.Integer];
	}

	override uint Size() => 2;

	override ubyte[] Assemble(ErrorInfo error, Node[] params) {
		ValidParams(error, params);

		auto value = (cast(IntegerNode) params[0]).value & 0xFF;

		return [opcode] ~ cast(ubyte) value;
	}
}

class InstPP : Instruction {
	this(ubyte pop) {
		opcode     = pop;
		paramTypes = [NodeType.RegPair, NodeType.RegPair];
	}

	override uint Size() => 2;

	override ubyte[] Assemble(ErrorInfo error, Node[] params) {
		ValidParams(error, params);

		auto r1 = (cast(RegPairNode) params[0]).name;
		auto r2 = (cast(RegPairNode) params[1]).name;

		return [opcode] ~ (
			cast(ubyte) (CompileRegPair(r1) << 4) |
			cast(ubyte) (CompileRegPair(r2) & 0x0F)
		);
	}
}

class Inst0PDDDDDD : Instruction {
	this(ubyte pop) {
		opcode     = pop;
		paramTypes = [NodeType.RegPair, NodeType.Integer];
	}

	override uint Size() => 5;

	override ubyte[] Assemble(ErrorInfo error, Node[] params) {
		ValidParams(error, params);

		auto reg = (cast(RegPairNode) params[0]).name;
		auto val = cast(uint) ((cast(IntegerNode) params[1]).value & 0xFFFFFF);

		return [opcode] ~ CompileRegPair(reg) ~ AddrNativeToYeti(val);
	}
}

class InstPR : Instruction {
	this(ubyte pop) {
		opcode     = pop;
		paramTypes = [NodeType.RegPair, NodeType.Register];
	}

	override uint Size() => 2;

	override ubyte[] Assemble(ErrorInfo error, Node[] params) {
		ValidParams(error, params);

		auto r1 = (cast(RegPairNode) params[0]).name;
		auto r2 = (cast(RegisterNode) params[1]).name;

		return [opcode] ~ (
			cast(ubyte) (CompileRegPair(r1) << 4) |
			cast(ubyte) (CompileRegister(r2) & 0x0F)
		);
	}
}

class InstRP : Instruction {
	this(ubyte pop) {
		opcode     = pop;
		paramTypes = [NodeType.Register, NodeType.RegPair];
	}

	override uint Size() => 2;

	override ubyte[] Assemble(ErrorInfo error, Node[] params) {
		ValidParams(error, params);

		auto r1 = (cast(RegisterNode) params[0]).name;
		auto r2 = (cast(RegPairNode) params[1]).name;

		return [opcode] ~ (
			cast(ubyte) (CompileRegister(r1) << 4) |
			cast(ubyte) (CompileRegPair(r2) & 0x0F)
		);
	}
}

class Inst0P : Instruction {
	this(ubyte pop) {
		opcode     = pop;
		paramTypes = [NodeType.RegPair];
	}

	override uint Size() => 2;

	override ubyte[] Assemble(ErrorInfo error, Node[] params) {
		ValidParams(error, params);

		auto reg = (cast(RegPairNode) params[0]).name;

		return [opcode] ~ CompileRegPair(reg);
	}
}

class InstRP0P : Instruction {
	this(ubyte pop) {
		opcode     = pop;
		paramTypes = [NodeType.Register, NodeType.RegPair, NodeType.RegPair];
	}

	override uint Size() => 3;

	override ubyte[] Assemble(ErrorInfo error, Node[] params) {
		ValidParams(error, params);

		auto r1 = (cast(RegisterNode) params[0]).name;
		auto r2 = (cast(RegPairNode) params[1]).name;
		auto r3 = (cast(RegPairNode) params[2]).name;

		return [opcode] ~ (
			cast(ubyte) (CompileRegister(r1) << 4) |
			cast(ubyte) (CompileRegPair(r2) & 0x0F)
		) ~ CompileRegPair(r3);
	}
}

class InstDDDDDD : Instruction {
	this(ubyte pop) {
		opcode     = pop;
		paramTypes = [NodeType.Integer];
	}

	override uint Size() => 4;

	override ubyte[] Assemble(ErrorInfo error, Node[] params) {
		ValidParams(error, params);

		auto val = cast(uint) ((cast(IntegerNode) params[0]).value & 0xFFFFFF);

		return opcode ~ AddrNativeToYeti(val);
	}
}

class AssemblerError : Exception {
	this() {
		super("", "", 0);
	}
}

class Assembler {
	Node[]              nodes;
	ubyte[]             bin;
	Instruction[string] insts;
	uint[string]        labels;
	long[string]        consts;

	this() {
		insts["nop"]   = new InstNoArgs(InstBin.NOP);
		insts["ldi"]   = new Inst0RDDDD(InstBin.LDI);
		insts["ldsi"]  = new Inst0RDD(InstBin.LDSI);
		insts["cpr"]   = new InstRR(InstBin.CPR);
		insts["cpp"]   = new InstPP(InstBin.CPP);
		insts["lda"]   = new Inst0PDDDDDD(InstBin.LDA);
		insts["setz"]  = new InstNoArgs(InstBin.SETZ);
		insts["sets"]  = new InstNoArgs(InstBin.SETS);
		insts["setc"]  = new InstNoArgs(InstBin.SETC);
		insts["clz"]   = new InstNoArgs(InstBin.CLZ);
		insts["cls"]   = new InstNoArgs(InstBin.CLS);
		insts["clc"]   = new InstNoArgs(InstBin.CLC);
		insts["getf"]  = new Inst0R(InstBin.GETF);
		insts["setf"]  = new Inst0R(InstBin.SETF);
		insts["wrb"]   = new InstPR(InstBin.WRB);
		insts["wrw"]   = new InstPR(InstBin.WRW);
		insts["wra"]   = new InstPP(InstBin.WRA);
		insts["rdb"]   = new InstRP(InstBin.RDB);
		insts["rdw"]   = new InstRP(InstBin.RDW);
		insts["rda"]   = new InstPP(InstBin.RDA);
		insts["bwrb"]  = new InstPR(InstBin.BWRB);
		insts["bwrw"]  = new InstPR(InstBin.BWRW);
		insts["bwra"]  = new InstPP(InstBin.BWRA);
		insts["brdb"]  = new InstRP(InstBin.BRDB);
		insts["brdw"]  = new InstRP(InstBin.BRDW);
		insts["brda"]  = new InstPP(InstBin.BRDA);
		insts["push"]  = new Inst0R(InstBin.PUSH);
		insts["pop"]   = new Inst0R(InstBin.POP);
		insts["pusha"] = new Inst0P(InstBin.PUSHA);
		insts["popa"]  = new Inst0P(InstBin.POPA);
		insts["add"]   = new InstRR(InstBin.ADD);
		insts["sub"]   = new InstRR(InstBin.SUB);
		insts["mul"]   = new InstRR(InstBin.MUL);
		insts["div"]   = new InstRR(InstBin.DIV);
		insts["idiv"]  = new InstRR(InstBin.IDIV);
		insts["mod"]   = new InstRR(InstBin.MOD);
		insts["imod"]  = new InstRR(InstBin.IMOD);
		insts["inc"]   = new Inst0R(InstBin.INC);
		insts["dec"]   = new Inst0R(InstBin.DEC);
		insts["incp"]  = new Inst0P(InstBin.INCP);
		insts["decp"]  = new Inst0P(InstBin.DECP);
		insts["addp"]  = new InstPR(InstBin.ADDP);
		insts["subp"]  = new InstPR(InstBin.SUBP);
		insts["diff"]  = new InstRP0P(InstBin.DIFF);
		insts["cmp"]   = new InstRR(InstBin.CMP);
		insts["icmp"]  = new InstRR(InstBin.ICMP);
		insts["shl"]   = new InstRR(InstBin.SHL);
		insts["shr"]   = new InstRR(InstBin.SHR);
		insts["and"]   = new InstRR(InstBin.AND);
		insts["or"]    = new InstRR(InstBin.OR);
		insts["xor"]   = new InstRR(InstBin.XOR);
		insts["not"]   = new Inst0R(InstBin.NOT);
		insts["out"]   = new InstRR(InstBin.OUT);
		insts["in"]    = new InstRR(InstBin.IN);
		insts["chk"]   = new Inst0R(InstBin.CHK);
		insts["actv"]  = new Inst0R(InstBin.ACTV);
		insts["jmp"]   = new InstDDDDDD(InstBin.JMP);
		insts["jmpb"]  = new InstDDDDDD(InstBin.JMPB);
		insts["jz"]    = new InstDDDDDD(InstBin.JZ);
		insts["jnz"]   = new InstDDDDDD(InstBin.JNZ);
		insts["js"]    = new InstDDDDDD(InstBin.JS);
		insts["jns"]   = new InstDDDDDD(InstBin.JNS);
		insts["jc"]    = new InstDDDDDD(InstBin.JC);
		insts["jnc"]   = new InstDDDDDD(InstBin.JNC);
		insts["jzb"]   = new InstDDDDDD(InstBin.JZB);
		insts["jnzb"]  = new InstDDDDDD(InstBin.JNZB);
		insts["jsb"]   = new InstDDDDDD(InstBin.JSB);
		insts["jnsb"]  = new InstDDDDDD(InstBin.JNSB);
		insts["jcb"]   = new InstDDDDDD(InstBin.JCB);
		insts["jncb"]  = new InstDDDDDD(InstBin.JNCB);
		insts["call"]  = new InstDDDDDD(InstBin.CALL);
		insts["callb"] = new InstDDDDDD(InstBin.CALLB);
		insts["ret"]   = new InstNoArgs(InstBin.RET);
		insts["int"]   = new InstDD(InstBin.INT);
		insts["hlt"]   = new InstNoArgs(InstBin.HLT);

		// aliases
		insts["je"]   = insts["jz"];
		insts["jne"]  = insts["jnz"];
		insts["jg"]   = insts["js"];
		insts["jng"]  = insts["jns"];
		insts["jl"]   = insts["jc"];
		insts["jnl"]  = insts["jnc"];
		insts["jeb"]  = insts["jzb"];
		insts["jneb"] = insts["jnzb"];
		insts["jgb"]  = insts["jsb"];
		insts["jngb"] = insts["jnsb"];
		insts["jlb"]  = insts["jcb"];
		insts["jnlb"] = insts["jncb"];
	}

	void Error(Char, A...)(ErrorInfo info, in Char[] fmt, A args) {
		ErrorBegin(info);
		stderr.writeln(format(fmt, args));
		throw new AssemblerError();
	}

	uint GetDataSize(InstructionNode node) {
		// no error checking, leave that until later
		uint size;

		foreach (ref param ; node.params) {
			switch (param.type) {
				case NodeType.String: {
					auto node2 = cast(StringNode) param;
					size += node2.value.length;
					break;
				}
				case NodeType.Integer: {
					auto node2 = cast(IntegerNode) param;

					switch (node.name) {
						case "db": size += 1; break;
						case "dw": size += 2; break;
						case "da": size += 3; break;
						default: assert(0);
					}
					break;
				}
				default: assert(0);
			}
		}

		return size;
	}

	void DataInstruction(InstructionNode node) {
		foreach (ref param ; node.params) {
			switch (param.type) {
				case NodeType.String: {
					auto node2 = cast(StringNode) param;
					
					if (node.name != "db") {
						Error(node.error, "String literals are only allowed in db");
					}

					bin ~= node2.value;
					break;
				}
				case NodeType.Integer: {
					auto node2 = cast(IntegerNode) param;

					switch (node.name) {
						case "db": bin ~= cast(ubyte) (node2.value & 0xFF); break;
						case "dw": bin ~= NativeToYeti!ushort(cast(ushort) node2.value); break;
						case "da": bin ~= AddrNativeToYeti(cast(uint) node2.value); break;
						default:   assert(0);
					}
					break;
				}
				default: assert(0);
			}
		}
	}

	void Assemble() {
		uint     programSize;
		string[] dataInstructions = ["db", "dw", "da"];

		foreach (ref inode ; nodes) {
			switch (inode.type) {
				case NodeType.Label: {
					auto node         = cast(LabelNode) inode;
					labels[node.name] = programSize;
					break;
				}
				case NodeType.Instruction: {
					auto node = cast(InstructionNode) inode;

					if (dataInstructions.canFind(node.name)) {
						programSize += GetDataSize(node);
						break;
					}

					if (node.name !in insts) {
						Error(node.error, "No such instruction '%s'", node.name);
					}

					programSize += insts[node.name].Size();
					break;
				}
				default: break;
			}
		}

		foreach (ref inode ; nodes) {
			switch (inode.type) {
				case NodeType.Label: break;
				case NodeType.Instruction: {
					auto   node = cast(InstructionNode) inode;
					Node[] params;

					foreach (ref param ; node.params) {
						switch (param.type) {
							case NodeType.Identifier: {
								auto node2 = cast(IdentifierNode) param;

								if (node2.name in labels) {
									params ~= new IntegerNode(labels[node2.name]);
								}
								else if (node2.name in consts) {
									params ~= new IntegerNode(consts[node2.name]);
								}
								else {
									Error(
										node.error, "Unknown identifier '%s'",
										node2.name
									);
								}
								break;
							}
							default: {
								params ~= param;
							}
						}
					}

					if (dataInstructions.canFind(node.name)) {
						DataInstruction(node);
						break;
					}

					try {
						bin ~= insts[node.name].Assemble(node.error, params);
					}
					catch (AssemblerException e) {
						Error(node.error, e.msg);
					}
					break;
				}
				case NodeType.Define: {
					auto node = cast(DefineNode) inode;

					if (node.name in consts) {
						Error(node.error, "Constant '%s' already defined", node.name);
					}

					consts[node.name] = node.value;
					break;
				}
				default: {
					Error(inode.error, "Unexpected %s node", inode.type);
				}
			}			
		}
	}
}
