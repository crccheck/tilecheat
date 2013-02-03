
build:
	coffee -c script.coffee


dev:
	@$(MAKE) -s -j2 devdev


# run server and coffeescript watcher
devdev: server jswatch


server:
	python -m SimpleHTTPServer


jswatch:
	coffee -wc -j script.coffee src/


.PHONY: build dev devdev server jswatch
