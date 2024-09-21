cp:
	@dmd -release -inline -boundscheck=off -O src/etysa.d src/ast/console_interface.d src/ast/node.d src/ast/exec.d src/ast/lexer.d src/ast/inter.d src/ast/parser.d src/ast/bytecode.d src/ast/bytecode2.d src/objects/function.d src/objects/object.d src/objects/type.d src/modules/importlib.d src/modules/base64.d src/modules/bytes.d src/modules/locals.d src/modules/map.d src/modules/dtypes.d src/modules/fs.d src/modules/json.d src/modules/list.d src/modules/math.d src/modules/path.d src/modules/process.d src/modules/random.d src/modules/regex.d src/modules/socket.d src/modules/string.d src/modules/sys.d src/modules/time.d src/modules/os.d src/modules/url.d src/modules/websocket.d src/modules/promises.d src/modules/number.d src/modules/thread.d
	@rm etysa.o
	@mv etysa ~/Desktop/dev/etysa

all:
	@dmd src/etysa.d src/ast/console_interface.d src/ast/node.d src/ast/exec.d src/ast/lexer.d src/ast/inter.d src/ast/parser.d src/ast/bytecode.d src/ast/bytecode2.d src/objects/function.d src/objects/object.d src/objects/type.d src/modules/importlib.d src/modules/base64.d src/modules/bytes.d src/modules/locals.d src/modules/map.d src/modules/dtypes.d src/modules/fs.d src/modules/json.d src/modules/list.d src/modules/math.d src/modules/path.d src/modules/process.d src/modules/random.d src/modules/regex.d src/modules/socket.d src/modules/string.d src/modules/sys.d src/modules/time.d src/modules/os.d src/modules/url.d src/modules/websocket.d src/modules/promises.d src/modules/number.d src/modules/thread.d
	@rm etysa.o
	@mv etysa ~/Desktop/dev/etysa

c:
	@ldc2 -release -boundscheck=off -O src/etysa.d src/ast/console_interface.d src/ast/node.d src/ast/exec.d src/ast/lexer.d src/ast/inter.d src/ast/parser.d src/ast/bytecode.d src/ast/bytecode2.d src/objects/function.d src/objects/object.d src/objects/type.d src/modules/importlib.d src/modules/base64.d src/modules/bytes.d src/modules/locals.d src/modules/map.d src/modules/dtypes.d src/modules/fs.d src/modules/json.d src/modules/list.d src/modules/math.d src/modules/path.d src/modules/process.d src/modules/random.d src/modules/regex.d src/modules/socket.d src/modules/string.d src/modules/sys.d src/modules/time.d src/modules/os.d src/modules/url.d src/modules/websocket.d src/modules/promises.d src/modules/number.d src/modules/thread.d
	@rm etysa.o
	@mv etysa ~/Desktop/dev/etysa

test:
	@./etysa app.tsa

i:
	@./etysa
