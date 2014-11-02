#!/usr/bin/env lsc
require! whatxml

js-bundle = \bundle.js

page = whatxml \html
  .. \head
    .. \title ._ "Bohr automaton"
    ..self-closing \link rel : \stylesheet  type : \text/css href : \main.css
  .. \body
    .. \div id : \main
      .. \div id : \game
      .. \script charset : \utf-8 src : js-bundle
      .. \p id : \footer
        .._ "©anko; "
        .. \a href : \https://github.com/anko/Bohr-Automaton
          .._ "code here"

console.log page.to-string!
