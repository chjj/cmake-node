all: node-x86.lib node-x64.lib

node-x86.lib:
	i686-w64-mingw32-dlltool -d node.def -y $@

node-x64.lib:
	x86_64-w64-mingw32-dlltool -d node.def -y $@

clean:
	-rm -f node-x86.lib node-x64.lib
