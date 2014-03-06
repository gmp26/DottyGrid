'use strict'

#
# simple module that adds line drawing
#
angular.module 'lines', <[trash commandStore]>
  .factory 'linesFactory', <[trash commandStore]> ++ (trash, commandStore) ->

    {partition} = require 'prelude-ls'

    class Line
      @id = 0
      ->
        @id = "line#{++@@id}"
        @selected = false
        @klass = "line"
        @klassmid = "mid-line"    
        @klassthin = "thin-line"    
        @data = {}
        @toggle = -> 
          @selected = !@selected
          @klassthin  = "thin-line " + if @selected then " opaque" else ""
        # @toggle = ->
        #   commandStore.newdo @, @doToggle, null, @doToggle
        @x1 = 0
        @y1 = 0
        @x2 = 0
        @y2 = 0

    do
      lines: []


      #
      # Bit of a code smell -- injecting scope in an initialiser
      #
      init: (scope) ->
        scope.blueDot = null
        @tool.enabled = -> true
        @scope = scope
        @lines = []

      # setter and getter
      model: -> @lines

      count: -> @lines.length

      remove: ->
        [@lines, binned] = partition ((line) -> !line.selected), @lines
        if binned.length > 0
          trash.binit "lines#{commandStore.pointer}", binned
          # console.log "binning id=lines#{commandStore.pointer}"
          # for line in binned
          # console.log "removing #{@line.id}"

      restore: ->
        id = "lines#{commandStore.pointer + 1}"
        lines = trash.unbin id
        if lines?
          for line in lines
            line.selected = true
            # console.log "restoring #{@line.id}"
          if lines && lines.length > 0
            @lines = lines ++ @lines
        else
          # console.log "no lines to restore"

      deleteSelection: -> {
        thisObj:@
        action: @remove
        params: null
        undo: @restore
      }


      tool:
        id: 'line'
        icon: 'pencil'
        label: 'Line'
        type: 'primary'
        tip: 'Click on 2 dots to draw a line'
        enabled: true
        weight: 1

      draw: (dot) ->
        if @lines.length > 0 && !@lines[*-1].data.p2?
          line = @lines[*-1]
        else
          line = new Line!
          @lines[*] = line

        if !@scope.lineFirst
          line.data.p1 = dot.p
          line.x1 = @scope.c2x dot.p.0
          line.y1 = @scope.r2y dot.p.1
          line.x2 = @scope.c2x dot.p.0
          line.y2 = @scope.r2y dot.p.1
          @scope.blueDot = {} 
          @scope.blueDot.x = @scope.c2x dot.p.0
          @scope.blueDot.y = @scope.r2y dot.p.1

          @scope.lineFirst = true
        else
          line.data.p2 = dot.p
          line.x2 = @scope.c2x dot.p.0
          line.y2 = @scope.r2y dot.p.1
          @scope.lineFirst = false
        @lines[*-1] = line

      undraw: ->
        # undraw the last dot drawn
        console.log "undraw line"
        if @scope.lineFirst
          @scope.lineFirst = false
          @scope.blueDot = null
          @lines.pop! unless @lines.length == 0
        else
          line = @lines[*-1]
          line.x2 = line.x1
          line.y2 = line.y1
          @scope.blueDot = @scope.getDot line.data.p1
          @scope.lineFirst = true
          delete line.data.p2

            


