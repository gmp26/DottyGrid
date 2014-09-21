'use strict'

#
# simple module that adds dot drawing
#
angular.module 'redDots', <[commandStore]>
  .factory 'redDotsFactory', <[commandStore]> ++ (commandStore) ->

    {partition} = require 'prelude-ls'

    class Dot
      @id = 0
      ->
        @id = "dot#{++@@id}"
        @data = {}
        @x = 0
        @y = 0

    do
      dots: []


      #
      # Bit of a code smell -- injecting scope in an initialiser
      #
      init: (scope) ->
        @tool.enabled = -> true
        @scope = scope
        @dots = []

      # setter and getter
      model: -> @dots

      count: -> @dots.length


      tool:
        id: 'redDot'
        icon: 'dot-circle-o'
        label: ''
        type: 'danger'
        tip: 'Draw a red dot.'
        enabled: true
        weight: 1

      draw: (dot) ->
        console.log "draw dot"
        @dots[*] = do
          x: (@scope.c2xIso dot.p.1) dot.p.0
          y: @scope.r2y dot.p.1

      undraw: ->
        # undraw the last dot drawn
        console.log "undraw dot"
        @dots.pop!




