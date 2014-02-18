'use strict'

{flatten} = require 'prelude-ls'

#
# simple module that adds polygon drawing
#
angular.module 'polygons', []
  .factory 'polygonsFactory', ->

    class Polygon
      ->
        @selected = false
        @klass = "polygon"
        @data = []
        @ppoints = ""
        @toggle = ->
          @selected = !@selected
          @klass = "polygon " + if @selected then " opaque" else ""

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
        @polygons = @polygons.filter (polygon) -> !polygon.selected
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

      draw: (dot) ->
        polygon = @polygons[*-1]

        if dot.active
          if !dot.first
            return

          # close polygon and save in polygons array
          if polygon.data.length > 2
            @polygons[*] = @setPoints new Polygon()
          else
            polygon.data = []
            polygon.points = ""
          @scope.closeAllDots!
        else
          # append dot to current polygon
          if dot.active
            return
          polygon.data[*] = dot.p
          @setPoints polygon
          dot.active = @polygons.length
          dot.first = polygon.data.length == 1

        @tracePolygons!



