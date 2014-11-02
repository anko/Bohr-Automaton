require! d3
{ empty, find, minimum-by } = require \prelude-ls

# Load sound effects

audio-context = do
  constructor = window.AudioContext or window.webkitAudioContext
  if constructor then new constructor! else null
sfx = do
  construct = (buffer, volume) ->
    play = ->
      return if not audio-context # Bail if no WebAudio support
      # Play it
      audio-context.create-buffer-source!
        ..buffer = buffer
        ..connect (audio-context.create-gain!
          ..gain.value = volume
          ..connect audio-context.destination)
        ..start 0

load-sfx = (src, volume, cb) ->
  d3.xhr src
    ..response-type \arraybuffer
    ..get (e, data) ->
      if e then cb e
      else
        if audio-context
          audio-context.decode-audio-data data.response, ->
            cb null, new sfx it, volume
        else
          console.log "WebAudio not supported; audio disabled."
          cb null sfx null null # Return no-op

e, sfx-start   <- load-sfx \start.wav   0.5
e, sfx-blop    <- load-sfx \blop.wav    1
e, sfx-nope    <- load-sfx \nope.wav    1
e, sfx-success <- load-sfx \success.wav 0.7
e, sfx-touch   <- load-sfx \touch.wav   1.2

sfx-start!

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

# Level definitions
#
# Each of the first few levels teaches the player something. Comments describe
# what that something is intended to be.
#
levels =
  * # Lessons:
    #  - Press on middle button to start
    #  - Green things move clockwise
    #  - Green things can kill multiple reds
    n-angles  : 3
    n-heights : 1
    creatures :
      * [ 1 0 ]
      * [ 2 0 ]
    charges :
      * [ 0 0 ]
      ...
  * # Lessons:
    #  - There can be multiple heights
    #  - You can change where the green things start
    n-angles  : 3
    n-heights : 2
    creatures:
      * [ 1 1 ]
      * [ 2 1 ]
    charges:
      * [ 0 0 ]
      ...
  * # Lessons:
    #  - There can be multiple green things
    n-angles  : 5
    n-heights : 2
    creatures:
      * [ 1 0 ]
      * [ 2 1 ]
    charges:
      * [ 0 0 ]
      * [ 3 0 ]
  * # Lessons:
    #  - Things with arrows imply switching higher or lower
    #  - The height-modifier is persistent until touching something else
    n-angles  : 4
    n-heights : 5
    creatures:
      * [ 0 4 \down ]
      * [ 0 0 ]
      * [ 1 0 ]
      * [ 2 0 ]
    charges:
      * [ 0 1 ]
      ...
  * # Lessons:
    #  - You might have to clear a path for another blue thing
    n-angles  : 6
    n-heights : 3
    creatures:
      * [ 0 2 ]
      * [ 1 1 ]
      * [ 2 1 \up ]
      * [ 3 2 \up ]
      * [ 4 2 \down ]
      * [ 5 1 ]
    charges:
      * [ 3 0 ]
      * [ 0 0 ]

levels-completed = {}

level = (n) ->

  creature = do
    id = 0
    (angle=0, height=0, direction=\none) ->
      { angle, height, direction, id : id++ }

  charge = do
    id = 0
    (angle, height, direction=\none) ->
      { angle, height, direction, id : id++ }

  return unless levels[n]

  ^^levels[n]
    ..creatures .= map -> creature.apply null, it
    ..charges   .= map -> charge  .apply null, it

# Game state object; holds things that change.
game =
  level : 0
  state : \none # Possible: running, loading, none
  creatures : []
  charges   : []
  update-time-step : 500ms
  n-angles  : 0
  n-heights : 0
  angles  : []
  heights : []

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
  lines-layer             = game-svg.append \g
  creature-layer          = game-svg.append \g
  charge-layer            = game-svg.append \g
  planet-background-layer = game-svg.append \g
  level-indicator-layer   = game-svg.append \g
  planet-layer            = game-svg.append \g
  drag-layer              = game-svg.append \g

  drag-charge = do

    find-coordinates = (angle, height) ->
      x : game.heights[height] * Math.cos game.angles[angle]
      y : game.heights[height] * Math.sin game.angles[angle]

    distance-between = (a, b) ->
      Math.sqrt ((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 )

    all-positions = ->
      r = []
      [ 0 til game.n-heights ].for-each (height) ->
        [0 til game.n-angles ] .for-each (angle) ->
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
        new-best-pos = minimum-by do
          ->
            distance-between do
              find-coordinates it.angle, it.height
              mouse-pos!
          drag-state.ok-positions
        if new-best-pos isnt drag-state.best-pos
          sfx-touch!
        drag-state.best-pos = new-best-pos
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

  # These are static, so we only need to append them once
  planet-radius = 35
  do
    # Planet background
    planet-background-layer.append \circle .attr r : min-orbit-r * 0.8
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
            d3.hsl planet-col .brighter 0.2
      .on \mouseout ->
        d3.select this .style do
          fill : planet-col
      .on \mousedown ->
        d3.select this .style do
          fill : d3.hsl planet-col .darker 0.5
      .on \mouseup ->
        d3.select this .style do
          fill : planet-col

  # Return actual render method
  (options={}) ->

    do
      angle-increment = 2 * Math.PI / levels.length
      radius = 3
      distance = planet-radius + radius * 5

      render-bind do
        \.level-button level-indicator-layer, levels, null
        ->
          this.append \circle
            .attr class : \level-button r : radius, cx : 0 cy : 0
            .style fill : \none, "stroke-width" : 0.5, stroke : planet-col
            .transition!duration 900
            .delay (_,i) -> 300 + i * 50
            .attr do
              cx : (_,i) -> distance * Math.cos (i * angle-increment)
              cy : (_,i) -> distance * Math.sin (i * angle-increment)
        (_,i) ->
          if levels-completed[i]
            d3.select this
              .style fill : planet-col
        (.remove!)

    # Orbit circles
    render-bind do
      \.orbit-circle lines-layer, game.heights, null
      -> this .append \circle
        ..attr r : 0 class : \orbit-circle
        ..call thinstroke
      (_, i) -> d3.select this .transition!duration 1000
        ..delay ((game.n-heights - i) * 100)
        ..attr r : -> it
      (.remove!)

    # Sector lines (at angles)
    render-bind do
      \.angle-line lines-layer, game.angles, null
      -> this.append \line
        ..call thinstroke
          ..attr x2 : 0 y2 : 0 class : \angle-line
      (_,i) -> d3.select this .transition!duration 500
        ..delay i * 50
        ..attr do
          x2 : -> (10 + max-orbit-r) * Math.cos it
          y2 : -> (10 + max-orbit-r) * Math.sin it
      (.remove!)

    # Radially moving objects
    do

      creature-height = 12
      creature-width  = 12

      reposition = (duration) ->
        ->
          height = game.heights[it.height]
          target = d3.select this
          if duration then target := target.transition!duration duration
          target .attr do
            \transform
            "rotate(#{rad-to-deg game.angles[it.angle]})"
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
            ..each reposition 300
        (data) ->
          d3.select this
            ..select \.head>path
              .transition!duration game.update-time-step
              .attr d : shape data.direction
            ..each reposition game.update-time-step * 0.7
        ->
          outer = this
          outer.select-all \.head
            .transition!duration game.update-time-step
            .delay game.update-time-step / 3
            .attr "transform" "scale(0)"
            .each \end ~> outer.remove!

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
            ..each reposition 300
        (data) ->
          d3.select this
            ..select \.head>path
              .transition!duration game.update-time-step
              .attr d : shape data.direction
            ..each reposition game.update-time-step * 0.7
        ->
          outer = this
          outer.select-all \.head
            .transition!duration game.update-time-step
            .delay game.update-time-step / 3
            .attr "transform" "scale(0)"
            .each \end ~> outer.remove!

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
      it.angle = (it.angle + 1) % game.n-angles
      it.height += switch it.direction
      | \up   => 1
      | \down => -1
      | _     => 0
      unless 0 <= it.height < game.n-heights
        dead-charges.push it

      game.creatures.for-each (c) ->
        if it `hits` c
          it.direction = c.direction
          dead-creatures.push c

    if dead-creatures.length > 0
      sfx-blop!

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

change-level = (n) ->

  game.creatures = level n .creatures
  game.charges   = level n .charges
  game.n-angles  = level n .n-angles
  game.n-heights = level n .n-heights
  game.angles = do
    incr = 2 * Math.PI / game.n-angles
    [ 0 til game.n-angles ] .map (* incr)
  game.heights = do

    switch game.n-heights
    | 1 => [ ((max-orbit-r + min-orbit-r) / 2) ]
    | _ =>
      incr = (max-orbit-r - min-orbit-r) / (game.n-heights - 1)
      [0 til game.n-heights].map (* incr) .map (+ min-orbit-r)

  render { +initial, +allow-drag }
  game.state = \none

window.change-level = (n) -> # For skipping levels in development
  change-level (game.level = n)

change-level game.level # Initial

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
  sfx-nope!
  stop-action!
  game.state = \loading
  set-timeout do # Restart level
    ->
      console.log "Restarting level"
      change-level game.level
    if options.delay? then options.delay else 1000

complete-level = ->
  return if game.state isnt \running
  levels-completed[game.level] = true
  if level game.level + 1 ?
    # Next level exists
    console.log "LEVEL #{game.level} COMPLETE!"
    stop-action!
    game.state = \loading
    set-timeout do
      ->
        sfx-success!
        change-level ++game.level
      1000
  else
    console.log "YOU WIN THE GAME!"
