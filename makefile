export PATH := node_modules/.bin:$(PATH)
WEBSERVER = python -m http.server 8888

.PHONY: all html js css sfx serve watch

all: html js css sfx
js: client.ls
	browserify --verbose --debug -t liveify -o static/bundle.js client.ls
html: page.ls
	./page.ls > static/index.html
css: main.css
	myth main.css > static/main.css
sfx : sfx/start.wav sfx/blop.wav sfx/nope.wav sfx/success.wav
	ln --force --relative --symbolic sfx/start.wav static/
	ln --force --relative --symbolic sfx/blop.wav static/
	ln --force --relative --symbolic sfx/nope.wav static/
	ln --force --relative --symbolic sfx/success.wav static/

serve: all
	cd static; $(WEBSERVER)

watch: all
	# Compile LiveScript files as they change
	inotifywait --quiet -mr -e close_write --format "%f" client.ls |\
	while read file; do make js; done;
