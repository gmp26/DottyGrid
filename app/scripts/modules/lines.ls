'use strict'

#
# simple module that adds line drawing
#
angular.module 'lines', []
  .factory 'lines', -> 

    class Line
      (lines) -> 
        @selected = false
        @getClass = -> "line " + if @selected then "line opaque" else "line"
        @data = {}
        @parent = lines
        @toggle = -> @selected = !@selected 
        @x1 = 0
        @y1 = 0
        @x2 = 0
        @y2 = 0

    do
      lines: []

      init: (scope) ->
        @dotA = null
        @tool.enabled = true
        @scope = scope

      # setter and getter
      model: -> @lines

      count: -> @lines.length

      deleteSelection: ->
        @lines = @lines.filter (line) -> !line.selected
        @lines.length

      tool:
        id: 'line'
        icon: 'pencil'
        label: 'Draw line'
        type: 'primary'
        enabled: true

      dotA: null

      draw: (dot) ->
        if @lines.length > 0 && !@lines[*-1].data.p2?
          line = @lines[*-1]
        else
          line = new Line(this)
          @lines[*] = line

        if !@dotA
          line.data.p1 = dot.p
          line.x1 = @scope.c2x dot.p.0
          line.y1 = @scope.r2y dot.p.1
          line.x2 = @scope.c2x dot.p.0
          line.y2 = @scope.r2y dot.p.1

          dot.first = true
          @dotA = dot 
        else
          line.data.p2 = dot.p
          line.x2 = @scope.c2x dot.p.0
          line.y2 = @scope.r2y dot.p.1
          @dotA.first = false
          @dotA = null
        @lines[*-1] = line



