export PATH := node_modules/.bin:$(PATH)
WEBSERVER = python -m http.server 8888

all: html js css
js: client.ls
	browserify --verbose --debug -t liveify -o static/bundle.js client.ls
html: page.ls
	./page.ls > static/index.html
css: main.css
	myth main.css > static/main.css

serve: all
	cd static; $(WEBSERVER)

watch: all
	# Compile LiveScript files as they change
	inotifywait --quiet -mr -e close_write --format "%f" client.ls |\
	while read file; do make js; done;
