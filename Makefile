.PHONY: all
all: get-free-port

get-free-port: get-free-port.asm
	nasm  -f bin -o $@ $<
	chmod        +x $@
