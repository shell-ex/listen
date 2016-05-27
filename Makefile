all:
	gcc main.c

test:
	./test.sh ./listen.rb
	./test.sh ./listen
