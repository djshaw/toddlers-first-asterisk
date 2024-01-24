all: dialplan.svg

%.svg: %.dot Makefile
	dot -Tsvg $< > $@
