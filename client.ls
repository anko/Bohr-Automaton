require! d3

console.log "Hi, I'm alive."

planet-col = \#157fc9

width  = 500px
height = 500px

game-svg = d3.select \body .select \#game
  .append \svg
  .attr { width, height }
  .append \g
  .attr transform : "translate(#{width/2},#{height/2})rotate(-90)"

min-orbit-r = 100
max-orbit-r = 200
n-orbits    = 3

orbit-heights = do
  incr = (max-orbit-r - min-orbit-r) / (n-orbits - 1)
  [0 til n-orbits].map (* incr) .map (+ min-orbit-r)

thinstroke = ->
  this.style do
    fill : \none
    stroke : d3.hcl planet-col .brighter 2

orbit-circles = game-svg.select-all \.orbit-circle
  .data orbit-heights
    ..enter!
      .append \circle
        ..attr do
            r : 0
            class : \orbit-circle
        ..call thinstroke
        ..transition!
          ..duration 1000
          ..delay (_,i) -> (orbit-heights.length - i) * 100
          ..attr r : -> it
    ..exit!remove!

n-angles = 9
angles = do
  incr = 2 * Math.PI / n-angles
  [ 0 til n-angles ] .map (* incr)

angle-lines = game-svg.select-all \.angle-line
  ..data angles
    ..enter!
      .append \line
        ..call thinstroke
          ..attr x2 : 0 y2 : 0
        ..transition!duration 500
          ..delay (_,i) -> i * 50
          ..attr do
            x2 : -> (10 + max-orbit-r) * Math.cos it
            y2 : -> (10 + max-orbit-r) * Math.sin it
    ..exit!remove!

planet = game-svg.append \circle .attr cx : 0 cy : 0 r : 25
  .style fill : planet-col
