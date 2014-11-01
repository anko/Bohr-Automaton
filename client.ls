require! d3
{ empty, find, minimum-by } = require \prelude-ls

console.log "Hi, I'm alive."

planet-col   = \#00e6c7
line-col     = \gray
creature-col = \#c91515
creature-bg-col = d3.hsl creature-col
  ..l = 0.95
charge-col   = planet-col
charge-bg-col = d3.hsl charge-col
  ..l = 0.95
drag-target-col = \orange

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

# Level generator
# (It's deterministic; nothing procedural.)
level = ->

  creature = do
    id = 0
    (angle=0, height=0, direction=\none) ->
      { angle, height, direction, id : id++ }

  charge = do
    id = 0
    (angle, height, direction=\none) ->
      { angle, height, direction, id : id++ }

  switch it
  | 0 =>
    creatures:
      * creature 0 0
      * creature 1 1 \down
      * creature 2 2 \up
    charges:
      * charge 4 0 \down
      * charge 4 1
      * charge 4 2
  | 1 =>
    creatures:
      * creature 0 0
      * creature 0 1 \down
      * creature 2 0
    charges:
      * charge 4 0 \down
      * charge 4 1
  | _ => null

# Game state object; holds things that change.
game =
  level : 0
  state : \none # Possible: running, loading, none
  creatures : []
  charges   : []
  update-time-step : 500ms

change-level = (n) ->
  game.creatures = level n .creatures
  game.charges   = level n .charges

change-level game.level # Initial

# Game frame SVG, with origin set to centre
game-svg = d3.select \body .select \#game
  .append \svg
  .attr { width, height }
  .append \g
  .attr transform : "translate(#{width/2},#{height/2})rotate(-90)"

# Control actions to influence game state
var start-action, stop-action
var fail-level, complete-level

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
  drag-layer     = game-svg.append \g

  drag-charge = do

    find-coordinates = (angle, height) ->
      x : orbit-heights[height] * Math.cos angles[angle]
      y : orbit-heights[height] * Math.sin angles[angle]

    distance-between = (a, b) ->
      Math.sqrt ((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 )

    all-positions = ->
      r = []
      [ 0 til n-orbits ].for-each (height) ->
        [0 til n-angles ] .for-each (angle) ->
          r.push { angle, height }
      return r

    creature-at-position = (angle, height) ->
      find do
        -> it.angle is angle and it.height is height
        game.creatures
    charge-at-position = (angle, height) ->
      find do
        -> it.angle is angle and it.height is height
        game.charges

    position-is-free-for-drop = (angle, height, this-charge-id) ->
      return false if creature-at-position angle, height
      c = charge-at-position angle, height
      if c and c.id isnt this-charge-id then return false
      return true

    find-possible-positions = (this-charge-id) ->
      a = all-positions!
      a.filter -> position-is-free-for-drop it.angle, it.height, this-charge-id

    mouse-pos = ->
      # D3 gives mouse positions back as an array; we want an object.
      [ x, y ] = d3.mouse game-svg.node!
      { x, y }

    drag-state =
      ok-positions : []   # Free positions (OK to drop in)
      best-pos     : null # Whichever is nearest the pointer

    d3.behavior.drag!
      .on \dragstart ->
        drag-state.ok-positions := find-possible-positions it.id
          ..for-each (pos) ->
            { x, y } = find-coordinates pos.angle, pos.height
            drag-layer.append \circle
              .attr cx : x, cy : y, r : 0
              .style fill : drag-target-col
              .transition!
              .duration 100
              .delay 0.75 * distance-between { x, y }, mouse-pos!
              .attr r : 2.5
        drag-layer.append \circle
          .attr cx : 0, cy : 0, r : 15 id : \target-indicator
          .style display : \none fill : drag-target-col, opacity : 0.2
        { x : initial-x, y : initial-y } = find-coordinates it.angle, it.height
        drag-layer.append \line
          .attr x1 : initial-x, y1 : initial-y, id : \target-indicator-line
          .style do
            display : \none
            stroke : drag-target-col
            "stroke-dasharray" : "2 2"

      .on \drag ->
        drag-state.best-pos = minimum-by do
          ->
            distance-between do
              find-coordinates it.angle, it.height
              mouse-pos!
          drag-state.ok-positions
        { best-pos } = drag-state
        { x, y } = find-coordinates best-pos.angle, best-pos.height
        game-svg.select \#target-indicator
          .attr transform : "translate(#x,#y)"
          .style display : \block
        game-svg.select \#target-indicator-line
          .attr x2 : x, y2 : y
          .style display : \block

      .on \dragend ->
        { best-pos } = drag-state
        if best-pos # In case this was just a click (`.on \drag` never fired)
          it <<< best-pos
        render { +allow-drag }
        drag-layer.select-all "circle"
          .transition!duration 200
          .ease \circle-in
          .attr r : 0
          .remove!
        drag-layer.select-all "line"
          .transition!duration 200
          .style "stroke-width" 0
          .remove!
        drag-state.best-pos = null

  # This is static, so we only need to append it once
  do
    planet-radius = 35
    # Planet background
    planet-layer.append \circle .attr r : min-orbit-r * 0.8
      .style fill : \white opacity : 0.65
    # Main planet
    planet-layer.append \circle .attr cx : 0 cy : 0 r : planet-radius
      .style fill : planet-col
      .on \click ->
        switch game.state
        | \none => start-action!
        | \running => fail-level { delay : 0 }
        | _ => # nothing
      .on \mouseover ->
        d3.select this .style do
          fill : do
            d3.hsl planet-col .brighter 0.5
      .on \mouseout ->
        d3.select this .style do
          fill : planet-col

  # Return actual render method
  (options={}) ->
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

      creature-height = 12
      creature-width  = 12

      reposition = (duration) ->
        ->
          height = orbit-heights[it.height]
          target = d3.select this
          if duration then target := target.transition!duration duration
          target .attr do
            \transform
            "rotate(#{rad-to-deg angles[it.angle]})"
          target.select \.head .attr \transform "translate(#height)"

      # Some SVG path specs for different shapes
      shape = (direction) ->
        w = creature-width
        h = creature-height
        switch (direction or \none)
        | \none => # Square shape
          "M0 0
           L#w 0
           L#w #h
           L0 #h"
        | \up =>   # Upward arrow-head
          "M#{w/2} 0
           L#w #h
           L#{w/2} #{h * 0.8}
           L0 #h
           z"
        | \down => # Downward arrow-head
          "M#{w/2} #h
           L#w 0
           L#{w/2} #{h * 0.2}
           L0 0
           z"

      # The "creature" and "charge" objects are the ones that float on orbits
      # around the central planet.
      #
      # They're positioned on a "rotating base" that determines their rotation.
      # The radius of their orbit is determined by an inner "head" group.  This
      # is done such that transitions of each can happen independently, so that
      # the objects stick to their orbits instead of taking straight lines
      # between points.

      render-bind do
        \.creature creature-layer, game.creatures, (.id)
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
            .transition!duration game.update-time-step
            .delay game.update-time-step / 3
            .attr "transform" "scale(0)"
            .remove!

      charge-elements = render-bind do
        \.charge charge-layer, game.charges, (.id)
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
              .transition!duration game.update-time-step
              .attr d : -> shape data.direction
            ..each reposition 200
        (.remove!)

      if options.allow-drag then charge-elements.call drag-charge
      else charge-elements.on \mousedown.drag null

# Initial render
render { +initial, +allow-drag }

update = do

  # Update helpers

  hits = (thing-a, thing-b) ->
    if thing-a.angle  is thing-b.angle
      and thing-a.height is thing-b.height then return true

  remove = (array, element) ->
    array.splice do
      array.index-of element
      1

  -> # Actual update method

    # Store what should be deleted after iteration.
    # (Doing it during iteration messes up ordering.)
    dead-charges = []
    dead-creatures = []
    game.charges.map ->
      it.angle = (it.angle + 1) % angles.length
      it.height += switch it.direction
      | \up   => 1
      | \down => -1
      | _     => 0
      unless 0 <= it.height < n-orbits
        dead-charges.push it

      game.creatures.for-each (c) ->
        if it `hits` c
          it.direction = c.direction
          dead-creatures.push c

    # OK, now it's safe to do the dead-removal splicing.
    dead-charges.for-each ->
      game.charges `remove` it
    dead-creatures.for-each ->
      game.creatures `remove` it
    render!
    if empty game.creatures
      return complete-level!
    if empty game.charges
      return fail-level!

var upd-interval
start-action = ->
  return if game.state is \running
  game.state = \running
  upd-interval := set-interval do
    update
    game.update-time-step
  update! # first update instantly

stop-action = ->
  game.state = \none
  clear-interval upd-interval

fail-level = (options={}) ->
  return if game.state isnt \running
  console.log "OOPS, THAT FAILED."
  stop-action!
  game.state = \loading
  set-timeout do # Restart level
    ->
      console.log "Restarting level"
      change-level game.level
      render { +initial, +allow-drag }
      game.state = \none
    if options.delay? then options.delay else 1000

complete-level = ->
  return if game.state isnt \running
  if level game.level + 1 ?
    # Next level exists
    console.log "LEVEL #{game.level} COMPLETE!"
    stop-action!
    game.state = \loading
    set-timeout do
      ->
        change-level ++game.level
        render { +initial, +allow-drag }
        game.state = \none
      1000
  else
    console.log "YOU WIN THE GAME!"
