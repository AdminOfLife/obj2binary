all: obj2binary

clean:
	rm bison.hpp bison.cpp lex.cpp obj2binary

bison.cpp: bison.y
	/usr/bin/bison -d -o $@ $^

lex.cpp: lex.l
	flex -o $@ $^

only: bison.cpp lex.cpp
	g++ -g -std=c++11 -o $@ $^

obj2binary: bison.cpp lex.cpp
	g++ -g -std=c++11 -o $@ $^
