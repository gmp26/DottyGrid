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
        label: 'Draw shape'
        type: 'success'
        enabled: true
        weight: 2

      tracePolygons: ->
        console.log (@polygons.map (polygon)->polygon.data.length).join " "

      setPoints: (poly) ->
        screenPoints = poly.data.map @scope.cr2xy
        poly.points = (flatten screenPoints).join " "
        poly

      closeAllDots: (poly) ->
        for dotColRow in poly.data
          dot = @scope.grid.rows[dotColRow.1][dotColRow.0]
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

      loseFocus: ->
        # will be called when the polygon tool is deselected
        for poly in @polygons
          @closeAllDots poly




