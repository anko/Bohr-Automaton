require! d3
vector = require \vec2
{ join } = require \prelude-ls

console.log "Hi, I'm alive."

planet-col   = \cyan
line-col     = \gray
creature-col = \#c91515
charge-col   = \cyan

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
    shape  : \down
  * angle  : 2
    height : 2
    shape  : \up

charges =
  * angle  : 5
    height : 0
  ...

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
      stroke : d3.hcl line-col
      "stroke-width" : 0.2

  # Encapsulate the D3 pattern of "enter, update, exit"
  # See [here](http://bost.ocks.org/mike/join/) for more on that.
  render-bind = (selector, layer, data, enter, update, exit) ->
    base = layer.select-all selector .data data
      ..enter!call enter
      ..call update
      ..exit!call exit

  # Enforce stacking order
  lines-layer    = game-svg.append \g
  creature-layer = game-svg.append \g
  charge-layer   = game-svg.append \g
  planet-layer   = game-svg.append \g

  # This is static, so we only need to append it once
  planet = planet-layer.append \circle .attr cx : 0 cy : 0 r : 25
    .style fill : planet-col

  # Return actual render method
  ->
    # Orbit circles
    render-bind do
      \.orbit-circle lines-layer, orbit-heights
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
      \.angle-line lines-layer, angles
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

    # Radially moving objects
    do

      creature-height = 10
      creature-width  = 10

      reposition = (duration) ->
        ->
          height = orbit-heights[it.height]
          target = d3.select this
          if duration then target := target.transition!duration duration
          target .attr do
            \transform
            "rotate(#{rad-to-deg angles[it.angle]})"
          target.select \.head .attr \transform "translate(#height)"

      shape = ->
        w = creature-width
        h = creature-height
        switch (it.shape or \equals)
        | \equals =>
          d3.select this
            .attr d : "M0 0
                       L#w 0
                       L#w #h
                       L0 #h
                       z"
            .style do
              fill : creature-col
              stroke : \none
        | \up =>
          d3.select this
            .attr d : "M#{w/2} 0
                       L#w #h
                       L#{w/2} #{h * 0.8}
                       L0 #h
                       z"
            .style do
              fill : creature-col
              stroke : \none
        | \down =>
          d3.select this
            .attr d : "M#{w/2} #h
                       L#w 0
                       L#{w/2} #{h * 0.2}
                       L0 0
                       z"
            .style do
              fill : creature-col
              stroke : \none

      render-bind do
        \.creature creature-layer, creatures
        ->
          rotating-base = this.append \g
            ..attr class : \creature
          head = rotating-base.append \g
            ..attr class : \head
            ..append \path
              .attr do
                transform : "rotate(90)translate(#{- creature-width/2},#{- creature-height/2})"
              .each shape
          rotating-base
            ..each reposition 0
        ->
          this.each reposition 300
        (.remove!)

      render-bind do
        \.charge charge-layer, charges
        ->
          rotating-base = this.append \g
            ..attr class : \charge
          head = rotating-base.append \g
            ..append \rect
              .attr do
                class : \head
                width  : creature-width
                height : creature-height
                x : - creature-width / 2
                y : - creature-height / 2
              .style \fill charge-col
          rotating-base
            ..each reposition 0
        ->
          this.each reposition 200
        (.remove!)

render { +initial }

update = ->
  charges.map -> it.angle = (it.angle + 1) % angles.length
  render!

set-interval do
  update
  500
