import std.stdio;

import std.string: strip;
import std.format: format;
import std.path: absolutePath;
import std.algorithm.mutation: remove;
import std.file: readText, exists, isFile;

import LdObject, LdParser, LdLexer, LdNode, LdBytes, LdIntermediate, LdExec;

import importlib: SETUP_HEAP, _StartHeap, TRACEBACK;
import console_interface: start_cmdline, cmd_executor;


void _start_interpreter(string[] args) {
	string baseFile = absolutePath(args[0]);

	if (exists(baseFile) && isFile(baseFile)) {
		string code = readText(baseFile);

		auto toks = new _Lex(code).TOKENS;
		auto absTree = new _Parse(toks, baseFile).ast;
		auto lqBytecode = new _GenInter(absTree).bytez;

		auto _Heap = _StartHeap.dup;
		_Heap["-file-"] = new LdStr(baseFile);

		try
			new _Interpreter(lqBytecode, &_Heap);
		catch (Exception e) {
			writeln("Error tracks (recent call):");

			for(auto i=0; i < TRACEBACK.length; i++){
				auto track = TRACEBACK[i];
				writeln(format("  Trace (\"%s\", %d)", track.file, track.line));

				if (exists(track.file)){
					File bug = File(track.file, "r");

					for(uint l = 0; l < track.line-1; l++)
						bug.readln();

					write(format("     %s\n", strip(bug.readln())));
				}
			}

			if(TRACEBACK.length)
				write(format("%s: ", TRACEBACK[TRACEBACK.length-1].type));

			writeln(e.msg);
		}

	} else
		cmd_executor(args, baseFile);
}


int main(string[] args) {
	args = args.remove(0);

	SETUP_HEAP(args);

	if(!args.length)
		start_cmdline();
	else
		_start_interpreter(args);
	
	return 0;
}
