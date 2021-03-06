'use strict'

#
# simple module that adds dot drawing
#
angular.module 'orangeDots', <[commandStore]>
  .factory 'orangeDotsFactory', <[commandStore]> ++ (commandStore) ->

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
        id: 'orangeDot'
        icon: 'dot-circle-o'
        label: ''
        type: 'warning'
        tip: 'Draw an orange dot.'
        enabled: true
        weight: 1

      draw: (dot) ->
        console.log "draw dot"
        @dots[*] = do
          x: @scope.c2x dot.p.0
          y: @scope.r2y dot.p.1

      undraw: ->
        # undraw the last dot drawn
        console.log "undraw dot"
        @dots.pop!

            


