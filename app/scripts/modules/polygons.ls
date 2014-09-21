'use strict'

#
# simple module that adds polygon drawing
#
{flatten, partition} = require 'prelude-ls'

angular.module 'polygons', []
  .factory 'polygonsFactory', <[commandStore]> ++ (commandStore) ->

    class Polygon
      @n = 0
      @id = 0
      ->
        @id = "poly#{++@@id}"
        @selected = false
        @polyfill = "polyfill#{@@n}"
        @klass = @polyfill
        @data = []
        @ppoints = ""
        @@n := (@@n+1) % 8

    do
      polygons: [new Polygon()]

      init: (scope) ->
        @polygons = [new Polygon()]
        @tool.enabled = -> true
        @scope = scope

      # setter and getter
      model: -> @polygons

      count: -> @polygons.length

      tool:
        id: 'poly'
        icon: 'pencil-square-o'
        label: 'Shape'
        type: 'success'
        tip: 'Click dots to draw a shape. Finish by clicking back on the green dot'
        enabled: true
        weight: 3

      tracePolygons: ->
        console.log (@polygons.map (polygon)->polygon.data.length).join " "

      setPoints: (poly) ->
        screenPoints = poly.data.map @scope.cr2xyIso
        poly.points = (flatten screenPoints).join " "
        poly

      closeAllDots: (poly) ->
        @scope.polyFirst = false
        @scope.polyLast = false

      draw: (dot) ->
        polygon = @polygons[*-1]

        if @scope.polyFirst and dot.x == @scope.greenDot.x and dot.y == @scope.greenDot.y

          # close polygon and save in polygons array
          if polygon.data.length > 2
            @polygons[*] = @setPoints new Polygon()
          else
            polygon.data = []
            polygon.points = ""
          @closeAllDots polygon

        else
          # append dot to current polygon
          polygon.data[*] = dot.p
          @setPoints polygon

          if polygon.data.length > 1
            @scope.orangeDot =
              x: (@scope.c2xIso dot.p.1) dot.p.0
              y: @scope.r2y dot.p.1
            @scope.polyLast = true

          if polygon.data.length == 1
            @scope.polyFirst = true
            @scope.greenDot =
              x: (@scope.c2xIso dot.p.1) dot.p.0
              y: @scope.r2y dot.p.1

      undraw: ->
        # undraw the last dot
        # console.log "undraw polygon"

        polygon = @polygons.pop!
        points = polygon.data
        if points.length == 0
          # make the penultimate polygon current
          if @polygons.length > 0
            polygon = @polygons[*-1]
            points = polygon.data
            if points.length > 0
              @scope.polyFirst = true
              @scope.greenDot =
                x: (@scope.c2xIso points.0.1) points.0.0
                y: @scope.r2y points.0.1
              @scope.polyLast = true
              @scope.orangeDot =
                x: (@scope.c2xIso points[*-1].1) points[*-1].0
                y: @scope.r2y points[*-1].1
          else
            @polygons[*] = polygon
        else
          # remove the last point in the current polygon
          points.pop!
          @scope.polyFirst = false
          @scope.polyLast = false
          if points.length > 0
            @scope.polyFirst = true
            @scope.greenDot =
              x: (@scope.c2xIso points.0.1) points.0.0
              y: @scope.r2y points.0.1
          if points.length > 1
            @scope.polyLast = true
            @scope.orangeDot =
              x: (@scope.c2xIso points[*-1].1) points[*-1].0
              y: @scope.r2y points[*-1].1
          @polygons[*] = polygon
        @setPoints polygon







