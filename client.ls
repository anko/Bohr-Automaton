require! d3
vector = require \vec2
{ join } = require \prelude-ls

console.log "Hi, I'm alive."

planet-col = \#157fc9
creature-col = \#c91515

width  = 500px
height = 500px

min-orbit-r = 100
max-orbit-r = 200
n-orbits    = 3

orbit-heights = do
  incr = (max-orbit-r - min-orbit-r) / (n-orbits - 1)
  [0 til n-orbits].map (* incr) .map (+ min-orbit-r)

n-angles = 9
angles = do
  incr = 2 * Math.PI / n-angles
  [ 0 til n-angles ] .map (* incr)

creatures =
  * angle  : 0
    height : 0
  * angle  : 1
    height : 1
  * angle  : 2
    height : 2

game-svg = d3.select \body .select \#game
  .append \svg
  .attr { width, height }
  .append \g
  .attr transform : "translate(#{width/2},#{height/2})rotate(-90)"

render = do

  # Render helpers

  rad-to-deg = (/ Math.PI * 180)
  thinstroke = ->
    this.style do
      fill : \none
      stroke : d3.hcl planet-col
      "stroke-width" : 0.2

  # Encapsulate the D3 pattern of "enter, update, exit"
  # See [here](http://bost.ocks.org/mike/join/) for more on that.
  render-bind = (selector, data, enter, update, exit) ->
    base = game-svg.select-all selector .data data
      ..enter!call enter
      ..call update
      ..exit!call exit

  # This is static, so we only need to append it once
  planet = game-svg.append \circle .attr cx : 0 cy : 0 r : 25
    .style fill : planet-col


  # Return actual render method
  ->
    # Orbit circles
    render-bind do
      \.orbit-circle orbit-heights
      -> this .append \circle
        ..attr r : 0 class : \orbit-circle
        ..call thinstroke
        ..transition!
          ..duration 1000
          ..delay (_,i) -> (orbit-heights.length - i) * 100
          ..attr r : -> it
      -> # nothing
      (.remove!)

    # Sector lines (at angles)
    render-bind do
      \.angle-line angles
      -> this.append \line
        ..call thinstroke
          ..attr x2 : 0 y2 : 0 class : \angle-line
        ..transition!duration 500
          ..delay (_,i) -> i * 50
          ..attr do
            x2 : -> (10 + max-orbit-r) * Math.cos it
            y2 : -> (10 + max-orbit-r) * Math.sin it
      -> # nothing
      (.remove!)

    # Creatures
    do

      creature-width  = 12
      creature-height = 12

      reposition = (duration) ->
        ->
          height = orbit-heights[it.height]
          target = d3.select this
          if duration then target := target.transition!duration duration
          target .attr do
            \transform
            "rotate(#{rad-to-deg angles[it.angle]})"
          target.select \.head .attr \transform "translate(#height)"

      render-bind do
        \.creature creatures
        ->
          rotating-base = this.append \g
            ..attr class : \creature
          head = rotating-base.append \g
            ..append \rect
              .attr do
                class : \head
                width  : creature-width
                height : creature-height
                x : - creature-width / 2
                y : - creature-height / 2
              .style \fill creature-col
          rotating-base
            ..each reposition 0
        ->
          this.each reposition 300
        (.remove!)

render { +initial }

update = ->
  creatures.map -> it.angle = (it.angle + 1) % angles.length
  render!

set-interval do
  update
  1000
