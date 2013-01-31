
build:
	coffee -c script.coffee


dev:
	@$(MAKE) -s -j2 devdev


# run server and coffeescript watcher
devdev: server jswatch


server:
	python -m SimpleHTTPServer


jswatch:
	coffee -wc script.coffee


.PHONY: build dev devdev server jswatch
