require! d3

console.log "Hi, I'm alive."

planet-col = \#157fc9

width  = 500px
height = 500px

game-svg = d3.select \body .select \#game
  .append \svg
  .attr { width, height }
  .append \g
  .attr transform : "translate(#{width/2},#{height/2})"

min-orbit-r = 100
max-orbit-r = 200
n-orbits    = 3

orbit-heights = do
  incr = (max-orbit-r - min-orbit-r) / (n-orbits - 1)
  [0 til n-orbits].map (* incr) .map (+ min-orbit-r)

orbit-circles = game-svg.select-all \.orbit-circle
  .data orbit-heights
    ..enter!
      .append \circle
        ..attr do
            r : 0
            class : \orbit-circle
        ..style do
          stroke : planet-col
          fill : \none
        ..transition!
          ..duration 1000
          ..delay (_,i) -> (orbit-heights.length - i) * 100
          ..attr r : -> it
          ..style "stroke-dasharray" : "1 4"
    ..exit!remove!

planet = game-svg.append \circle .attr cx : 0 cy : 0 r : 25
  .style fill : planet-col

