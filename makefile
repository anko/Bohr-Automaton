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
sfx : sfx/start.wav sfx/blop.wav sfx/nope.wav sfx/success.wav sfx/touch.wav sfx/change.wav sfx/win.mp3
	cp -n --force sfx/start.wav static/
	cp -n --force sfx/blop.wav static/
	cp -n --force sfx/nope.wav static/
	cp -n --force sfx/success.wav static/
	cp -n --force sfx/touch.wav static/
	cp -n --force sfx/change.wav static/
	cp -n --force sfx/win.mp3 static/

serve: all
	cd static; $(WEBSERVER)

watch: all
	# Compile LiveScript files as they change
	inotifywait --quiet -mr -e close_write --format "%f" client.ls |\
	while read file; do make js; done;
