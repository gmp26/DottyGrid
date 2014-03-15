'use strict'

#
# simple module that adds polygon drawing
#
{flatten, partition} = require 'prelude-ls'

angular.module 'polygons', []
  .factory 'polygonsFactory', <[trash commandStore]> ++ (trash, commandStore) ->

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
        @toggle = ->

        # @toggle = ->
        #   @selected = !@selected
        #   @klass = @polyfill + if @selected then " opaque" else ""
          
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

      remove: !->
        [@polygons, deletions] = partition ((polygon) -> !polygon.selected), @polygons
        if deletions.length > 0
          trash.binit "poly#{commandStore.pointer}", deletions
          # console.log "binning id=poly#{commandStore.pointer}"
          for poly in deletions
            @closeAllDots poly
            # console.log "removing #{poly.id}"
          if @polygons.length == 0
            @polygons = [new Polygon()]
            # console.log "new empty poly #{@polygons.0.id}"


      restore: ->
        id = "poly#{commandStore.pointer + 1}"
        polygons = trash.unbin id
        if polygons?
          for polygon in polygons
            polygon.selected = true
            # console.log "restoring #{polygon.id}"
          if polygons && polygons.length > 0
            @polygons = polygons ++ @polygons
        else
          # console.log "no polygons restored"

      deleteSelection: -> {
        thisObj:@
        action: @remove
        params: null
        undo: @restore
      }

      tool:
        id: 'poly'
        icon: 'pencil-square-o'
        label: 'Shape'
        type: 'success'
        tip: 'Click dots to draw a shape. Finish by clicking back on the green dot'
        enabled: true
        weight: 2

      tracePolygons: ->
        console.log (@polygons.map (polygon)->polygon.data.length).join " "

      setPoints: (poly) ->
        screenPoints = poly.data.map @scope.cr2xy
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
              x: @scope.c2x dot.p.0
              y: @scope.r2y dot.p.1
            @scope.polyLast = true

          if polygon.data.length == 1
            @scope.polyFirst = true
            @scope.greenDot = 
              x: @scope.c2x dot.p.0
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
                x: @scope.c2x points.0.0
                y: @scope.r2y points.0.1
              @scope.polyLast = true
              @scope.orangeDot = 
                x: @scope.c2x points[*-1].0
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
              x: @scope.c2x points.0.0
              y: @scope.r2y points.0.1
          if points.length > 1
            @scope.polyLast = true
            @scope.orangeDot = 
              x: @scope.c2x points[*-1].0
              y: @scope.r2y points[*-1].1
          @polygons[*] = polygon
        @setPoints polygon







