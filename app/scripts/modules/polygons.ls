'use strict'

{flatten, partition} = require 'prelude-ls'

#
# simple module that adds polygon drawing
#
angular.module 'polygons', []
  .factory 'polygonsFactory', ->

    class Polygon
      @n = 0
      ->
        @selected = false
        @polyfill = "polyfill#{@@n}"
        @klass = @polyfill
        @data = []
        @ppoints = ""
        @toggle = ->
          @selected = !@selected
          @klass = @polyfill + if @selected then " opaque" else ""
        @@n := (@@n+1) % 8

    do
      polygons: [new Polygon()]

      init: (scope) ->
        @polygons = [new Polygon()]
        @tool.enabled = true
        @scope = scope

      # setter and getter
      model: -> @polygons

      count: -> @polygons.length

      deleteSelection: ->
        [@polygons, deletions] = partition ((polygon) -> !polygon.selected), @polygons
        for poly in deletions
          @closeAllDots poly
        if @polygons.length == 0
          @polygons = [new Polygon()]
        @polygons.length

      tool:
        id: 'poly'
        icon: 'pencil-square-o'
        label: 'Shape'
        type: 'success'
        enabled: true
        weight: 2

      tracePolygons: ->
        console.log (@polygons.map (polygon)->polygon.data.length).join " "

      setPoints: (poly) ->
        screenPoints = poly.data.map @scope.cr2xy
        poly.points = (flatten screenPoints).join " "
        poly

      getDot: (colRow) -> @scope.grid.rows[colRow.1][colRow.0]

      closeAllDots: (poly) ->
        for colRow in poly.data
          dot = @getDot colRow
          dot.active = false
          dot.polyFirst = false
        poly

      draw: (dot) ->
        polygon = @polygons[*-1]

        if dot.active
          if !dot.polyFirst
            return

          # close polygon and save in polygons array
          if polygon.data.length > 2
            @polygons[*] = @setPoints new Polygon()
          else
            polygon.data = []
            polygon.points = ""
          @closeAllDots polygon

        else
          # append dot to current polygon
          if dot.active
            return
          polygon.data[*] = dot.p
          @setPoints polygon
          dot.active = @polygons.length
          dot.polyFirst = polygon.data.length == 1

      undraw: ->
        # undraw the last dot
        console.log "undraw polygon"

        polygon = @polygons.pop!
        points = polygon.data
        if points.length == 0
          # make the penultimate polygon current
          polygon = @polygons[*-1]
          points = polygon.data
          if points.length > 0
            (@getDot points.0).polyFirst = true
            (@getDot points[*-1]).active = true
        else
          # remove the last point
          removed = @getDot points.pop!
          removed.active = false
          removed.polyFirst = false
          if points.length > 0
            (@getDot points[*-1]).active = true
          @polygons[*] = polygon
          @setPoints polygon







