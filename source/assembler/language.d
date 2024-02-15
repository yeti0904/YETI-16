module yeti16.assembler.language;

class Language {
	static const string[] registers = [
		"a", "b", "c", "d", "e", "f", "g", "h"
	];
	static const string[] regPairs = [
		"ab", "cd", "ef", "gh", "ip", "sp", "bs", "ds", "sr"
	];
}
