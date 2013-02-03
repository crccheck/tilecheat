
build:
	coffee -c script.coffee


dev:
	@$(MAKE) -s -j3 devdev


# run server and coffeescript watcher
devdev: server jswatch docs


server:
	python -m SimpleHTTPServer


# npm install coffee-script
jswatch:
	coffee -wc -j script.coffee src/


# npm install docco
docs:
	docco src/*.coffee


.PHONY: build dev devdev server jswatch docs
