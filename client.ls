require! d3
vector = require \vec2
{ empty } = require \prelude-ls

console.log "Hi, I'm alive."

planet-col   = \#00e6c7
line-col     = \gray
creature-col = \#c91515
creature-bg-col = d3.hsl creature-col
  ..l = 0.95
charge-col   = planet-col
charge-bg-col = d3.hsl charge-col
  ..l = 0.95

update-time-step = 1000ms

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

creature = do
  id = 0
  (angle=0, height=0, direction=\none) ->
    { angle, height, direction, id : id++ }

charge = do
  id = 0
  (angle, height, direction=\none) ->
    { angle, height, direction, id : id++ }

levels =
  * creatures:
      * creature 0 0
      * creature 1 1 \down
      * creature 2 2 \up
    charges:
      * charge 4 0 \down
      * charge 4 1
      * charge 4 2
  ...

creatures = []
charges   = []

current-level = 0

change-level = (n) ->
  level = levels[n]
  { creatures, charges } := level

change-level current-level

# Possible: running, win-screen, none
game-state = \running

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
  render-bind = (selector, layer, data, key, enter, update, exit) ->
    base = layer.select-all selector .data data, (key or null)
      ..enter!call enter
      ..each update
      ..exit!call exit

  # Enforce stacking order
  lines-layer    = game-svg.append \g
  creature-layer = game-svg.append \g
  charge-layer   = game-svg.append \g
  planet-layer   = game-svg.append \g

  # This is static, so we only need to append it once
  do
    planet-size = 25
    # Planet background
    planet-layer.append \circle .attr r : min-orbit-r * 0.8
      .style fill : \white opacity : 0.65
    # Main planet
    planet-layer.append \circle .attr cx : 0 cy : 0 r : 25
      .style fill : planet-col

  # Return actual render method
  ->
    # Orbit circles
    render-bind do
      \.orbit-circle lines-layer, orbit-heights, null
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
      \.angle-line lines-layer, angles, null
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

      shape = (direction) ->
        w = creature-width
        h = creature-height
        switch (direction or \none)
        | \none => "M0 0
                    L#w 0
                    L#w #h
                    L0 #h"
        | \up =>   "M#{w/2} 0
                    L#w #h
                    L#{w/2} #{h * 0.8}
                    L0 #h
                    z"
        | \down => "M#{w/2} #h
                    L#w 0
                    L#{w/2} #{h * 0.2}
                    L0 0
                    z"

      render-bind do
        \.creature creature-layer, creatures, (.id)
        ->
          rotating-base = this.append \g
            ..attr class : \creature
          head = rotating-base.append \g
            ..attr class : \head
            ..append \circle .attr r : 15
              .style fill : creature-bg-col, opacity : 0.80
            ..append \path
              .attr do
                transform : "rotate(90)translate(#{- creature-width/2},#{- creature-height/2})"
                d : -> shape it.direction
              .style fill : creature-col
          rotating-base
            ..each reposition 0
        ->
          d3.select this .each reposition 300
        ->
          this
            .transition!duration update-time-step
            .delay update-time-step / 3
            .attr "transform" "scale(0)"
            .remove!

      render-bind do
        \.charge charge-layer, charges, (.id)
        ->
          rotating-base = this.append \g
            ..attr class : \charge
          head = rotating-base.append \g
            ..attr class : \head
            ..append \circle .attr r : 15
              .style fill : charge-bg-col, opacity : 0.80
            ..append \path
              .attr do
                d : -> shape it.direction
                transform : "rotate(90)translate(#{- creature-width/2},#{- creature-height/2})"
              .style \fill charge-col
          rotating-base
            ..each reposition 0
        (data) ->
          d3.select this
            ..select \.head>path
              .transition!duration update-time-step
              .attr d : -> shape data.direction
            ..each reposition 200
        (.remove!)

render { +initial }

var level-completed, level-failed # callbacks; defined later

update = do

  hits = (thing-a, thing-b) ->
    if  thing-a.angle  is thing-b.angle
      and thing-a.height is thing-b.height then return true

  remove = (array, element) ->
    array.splice do
      array.index-of element
      1

  ->

    # Store what should be deleted after iteration.
    # (Doing it during iteration messes up ordering.)
    dead-charges = []
    dead-creatures = []
    charges.map ->
      it.angle = (it.angle + 1) % angles.length
      it.height += switch it.direction
      | \up   => 1
      | \down => -1
      | _     => 0
      unless 0 <= it.height < n-orbits
        dead-charges.push it

      creatures.for-each (c) ->
        if it `hits` c
          it.direction = c.direction
          dead-creatures.push c
          level-completed! if empty creatures

    # OK, now it's safe to do the dead-removal splicing.
    dead-charges.for-each ->
      charges `remove` it
    dead-creatures.for-each ->
      creatures `remove` it

    level-failed! if empty charges

    render!

upd-interval = set-interval do
  update
  update-time-step

stop-action = ->
  game-state := \none
  clear-interval upd-interval

level-failed = ->
  return if game-state isnt \running
  console.log "OOPS, THAT FAILED."
  stop-action!
  # TODO reload level

level-completed = ->
  return if game-state isnt \running
  if levels[current-level + 1]?
    # Next level exists
    console.log "LEVEL #current-level COMPLETE!"
    stop-action!
    # TODO load next level
  else
    console.log "YOU WIN THE GAME!"
