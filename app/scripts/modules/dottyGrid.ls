'use strict'

{flatten, reject} = require 'prelude-ls'

angular.module 'dottyGrid' []

  # define the toolset
  .factory 'toolset', -> [
    * id: 'line'
      icon: 'pencil'
      label: 'Draw line'
      type: 'primary'
      enabled: true
      active: ""
    * id: 'poly'
      icon: 'pencil-square-o'
      label: 'Draw shape'
      type: 'success'
      enabled: true
      active: "btn-lg"
    * id: 'camera'
      icon: 'sun-o'
      label: 'Add camera'
      type: 'info'
      enabled: true
      active: ""
    * id:'trash'
      icon: 'trash-o'
      label: 'Delete Selection'
      type: 'danger'
      enabled: true
      active: ""
  ]

  .controller 'dottyGridController', <[$scope toolset]> ++ ($scope, toolset) ->

    console.log "dottyGridController"
    $scope.toolset = toolset

    $scope.deleteSelection = ->
      $scope.polygons = reject (.selected), $scope.polygons

    $scope.currentTool = 'poly'

    $scope.toolCheck = (tool) ->
      if tool.id == 'trash'
        $scope.deleteSelection!
      else
        for t in $scope.toolset
          t.active = ""
          tool.active = "btn-lg"
          $scope.currentTool = tool.active

    $scope.trace = (col, row) ->
      console.log "(#{col}, #{row})"

    colCount = 50
    rowCount = 50

    # Pixels from centre of an edge dot to the svg container boundary
    inset = 20

    # Dot separation in pixels
    sep = 18
    scale = 1

    $scope.transform = ->
      return "scale(#{scale})"

    #
    # The scope model uses column, row coordinates, but the svg element
    # uses x,y pixel coordinates.
    #
    # Integer r,c values identify a grid dot
    # Non-integers may be allowed e.g. while tracking a mouse point with a
    # part-formed line.
    #

    #
    # Coordinate transform functions.
    # Lowercase c,r coords may be non-integer
    # Uppercase C,R coords are integers and can index a dot
    #
    # Note that columns and rows are numbered from bottom left!
    #
    $scope.c2x = d3.scale.linear!
    .domain [0,colCount-1]
    .range [inset, colCount*sep]

    $scope.x2c = $scope.c2x.invert
    $scope.x2C = (x) -> Math.round $scope.x2c x

    $scope.r2y = d3.scale.linear!
    .domain [0,rowCount-1]
    .range [rowCount*sep, inset]

    $scope.y2r = $scope.r2y.invert
    $scope.y2R = (y) -> Math.round $scope.y2r y

    $scope.cr2xy = (p) ->
      * $scope.c2x p.0
        $scope.r2y p.1

    $scope.xy2cr = (p) ->
      * $scope.x2c p.0
        $scope.y2r p.1

    $scope.xy2dot = (p) ->
      col = $scope.x2C p.0
      row = $scope.y2R p.1
      $scope.grid.rows[row][col]

    $scope.svgWidth = -> scale * (inset + $scope.c2x colCount-1)
    $scope.svgHeight = -> scale * (inset + $scope.r2y 0)

    #
    # dots in the dotty grid
    #

    rows = for rowIndex from 0 til rowCount
      for colIndex from 0 til colCount
        p: [colIndex, rowIndex]
        x: $scope.c2x colIndex
        y: $scope.r2y rowIndex
        first: false
        open: false

    $scope.grid = {rows: rows}

    $scope.classHash = (dot) -> do
      circle: true
      lit: dot.first

    $scope.closeAllDots = ->
      for rowIndex from 0 til rowCount
        row = $scope.grid.rows[rowIndex]
        for colIndex from 0 til colCount
          dot = row[colIndex]
          dot.open = false
          dot.first = false

    # previously constructed polygons
    $scope.polygons = [{data: []}]

    tracePolygons = ->
      console.log ($scope.polygons.map (polygon)->polygon.data.length).join " "

    $scope.lineDraw = (dot) ~>


    $scope.polyDraw = (dot) ~>
      polygon = $scope.polygons[*-1]
      if dot.open
        if !dot.first
          return

        # close polygon and save in polygons array
        if polygon.data.length > 2
          $scope.polygons.push({data: []})
        else
          polygon.data = []
        $scope.closeAllDots!
        console.log "close"
      else
        # append dot to current polygon
        if dot.open
          return
        polygon.data.push(dot.p)
        dot.open = $scope.polygons.length
        dot.first = polygon.data.length == 1
        console.log "open"
      tracePolygons!

    $scope.dotClick = (dot) ->
      switch $scope.currentTool
      | 'poly' => $scope.polyDraw dot

    $scope.polyPoints = (p) ->
      screenPoints = p.data.map $scope.cr2xy
      (flatten screenPoints).join " "

    $scope.polyClass = (p) ->
      "polygon " + if p.selected then "opaque" else ""

    $scope.polyToggle = (p) -> p.selected = !p.selected

    $scope.visipolys = [{data: []}]

    $scope.visiDraw = (dot) ->


  # .directive 'd3', <[]> ++ ->
  #   restrict: 'A'
  #   link: (scope, element, attrs) !->
  #     console.log "d3 directive"

  #     svg = d3.select element.0

  #     trace = ->
  #       p = [x,y] = d3.mouse element.0
  #       [c,r] = scope.xy2cr p
  #       dot = scope.xy2dot p
  #       console.log "#{d3.event.type} xy=(#{x},#{y}), cr=(#{c},#{r}), dot=(#{dot.p.0},#{dot.p.1})"

  #     selecter = ->
  #       p = d3.mouse element.0
  #       console.log "polyScope=#{element.scope!$index}"
  #       pos = scope.xy2cr p
  #       insideList = scope.polygons.filter (poly) ->
  #         poly.data.length > 2
  #         and VisibilityPolygon.inPolygon pos, poly.data.concat!
  #       for poly in insideList
  #         poly.selected = !poly.selected
  #       console.log insideList.length



      # svg.on "mouseover", trace
      # svg.on "mousedown", selecter
      # svg.on "mousemove", trace
      # svg.on "mouseup", trace
