'use strict'

{any, empty, filter, flatten, reject, sort-by, tail} = require 'prelude-ls'

angular.module 'dottyGrid' <[visibility lines polygons]>

  .constant 'constants' do
    showVis: 'Show visible'
    hideVis: 'Hide visible'
    eyeOpen: 'eye'
    eyeClose: 'eye-slash'

  # define the toolset
  .factory 'toolset', <[constants]> ++ (constants) -> [

    # * id: 'line'
    #   icon: 'pencil'
    #   label: 'Draw line'
    #   type: 'primary'
    #   enabled: true

    # * id: 'poly'
    #   icon: 'pencil-square-o'
    #   label: 'Draw shape'
    #   type: 'success'
    #   enabled: true
    #   active: "btn-lg"

    * id: 'camera'
      icon: 'sun-o'
      label: 'Add camera'
      type: 'info'
      enabled: true
      active: ""
      weight: 3
    # * id: 'visible'
    #   icon: constants.eyeOpen
    #   label: constants.showVis
    #   type: 'warning'
    #   enabled: true
    #   active: ""
    #   weight: 4
    * id:'trash'
      icon: 'trash-o'
      label: 'Delete selected'
      type: 'danger'
      enabled: true
      active: ""
      weight: 5
  ]

  .controller 'dottyGridController',
  <[
    $scope
    toolset
    linesFactory
    polygonsFactory
    constants
    VisibilityPolygon
  ]> ++ (
    $scope,
    toolset,
    linesFactory,
    polygonsFactory,
    constants,
    VisibilityPolygon
  ) ->

    console.log "dottyGridController"

    $scope.toolset = toolset

    plugins = []

    installPlugin = (plugin, name, active) ->
      plugin.init $scope
      plugin.name = name
      plugins[*] = plugin
      toolset[*] = plugin.tool
      $scope[name] = -> plugin.model!
      if active
        plugin.tool.active = "btn-lg"

      # install default tool button action
      plugin.toolAction ?= (tool) ->
        # select the tool button as currentTool, making it large, and the rest normal
        plugin.tool.active = ""
        $scope.currentTool = tool.id
        for t in $scope.toolset
          t.active = ""
        tool.active = "btn-lg"
        true

    installPlugin polygonsFactory, 'polygons', true
    installPlugin linesFactory, 'lines'
    $scope.toolset = sort-by (.weight), toolset

    $scope.VisibilityPolygon = VisibilityPolygon

    $scope.deleteSelection = ->
      # delegate to deletion hooks
      plugins.map (.deleteSelection!)

      # for plugin in plugins
      #   plugin.deleteSelection!

      remove = reject (.selected)
      $scope.cameras = remove $scope.cameras

      # if we deleted a containing polygon of a camera, make sure
      # we also delete that camera's visipols
      for camera in $scope.cameras
        unless any ((p)->p == camera.poly), $scope.polygons!
          $scope.visipolys = reject ((v)->v == camera.visipol), $scope.visipolys
          delete camera.poly
          delete camera.visipol

      $scope.visipolys = reject (==void), $scope.cameras.map (.visipol)

    $scope.currentTool = 'poly'

    $scope.toolCheck = (tool) ->

      # delegate to plugin toolActions
      for plugin in plugins
        if tool.id == plugin.tool.id
          return plugin.toolAction tool

      if tool.id == 'trash'
        $scope.deleteSelection!
      else
        # if tool.id == 'visible'
        #   $scope.toggleVisible tool
        # else
        for t in $scope.toolset
          t.active = ""
          tool.active = "btn-lg"
          $scope.currentTool = tool.id

    $scope.trace = (col, row) ->
      console.log "(#{col}, #{row})"

    colCount = 30
    rowCount = 30

    # Pixels from centre of an edge dot to the svg container boundary
    inset = 20

    # Dot separation in pixels
    sep = 30
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
        active: false

    $scope.grid = {rows: rows}

    $scope.classHash = (dot) -> do
      circle: true
      lit: dot.first

    $scope.closeAllDots = ->
      for rowIndex from 0 til rowCount
        row = $scope.grid.rows[rowIndex]
        for colIndex from 0 til colCount
          dot = row[colIndex]
          dot.active = false
          dot.first = false

    $scope.cameras = []

    $scope.cameraDraw = (dot) ->
      $scope.cameras[*] =
        data: dot.p


    $scope.cameraPoints = (c, component) ->
      p = c.data
      switch component
      | 'x1' => $scope.c2x p.0
      | 'y1' => $scope.r2y p.1
      | 'x2' => $scope.c2x p.0
      | 'y2' => $scope.r2y p.1

    $scope.dotClick = (dot) ->
      for plugin in plugins
        if $scope.currentTool == plugin.tool.id && plugin.draw
          plugin.draw dot
          $scope.makeVisibles!
          return

      # if $scope.currentTool == 'camera'
      #   $scope.cameraDraw dot

      $scope.makeVisibles!


    $scope.polyPoints = (p) ->
      screenPoints = p.data.map $scope.cr2xy
      (flatten screenPoints).join " "

    $scope.polyClass = (p) ->
      "polygon " + if p.selected then "opaque" else ""

    $scope.visiClass = (p) ->
      "visipoly " + if p.selected then "selected" else ""

    pointHash = (p) -> "#{p.0.toString 16}#{p.1.toString 16}"

    $scope.cameraClass = (c) ->
      "camera " + if c.selected then "opaque " else ""

    $scope.polyToggle = (p) -> p.selected = !p.selected

    $scope.cameraToggle = (c) ->
      c.selected = !c.selected
      if c.visipol
        c.visipol.selected = c.selected

    $scope.makeVisibles =  ->

      for camera in $scope.cameras

        for p, i in $scope.polygons!
          internal = VisibilityPolygon.inPolygon camera.data, p.data
          if typeof! internal is 'Array'
            # the camera is on the polygon border: adjust so it so is fractionally inside
            camera.data = internal
            console.log "adjusted = #{internal}"

          if internal
            poly = p
            break

        if internal
          cm = colCount - 1
          rm = rowCount - 1
          console.debug poly.data
          segments = VisibilityPolygon.convertToSegments [
            [[0, 0], [cm, 0], [cm, rm], [0, rm]]
            poly.data
          ]

          camera.poly = poly
          camera.visipol =
            selected: camera.selected
            data: VisibilityPolygon.compute camera.data, segments
        else
          delete camera.visipol

      $scope.visipolys = (filter (.visipol), $scope.cameras).map (.visipol)

  .directive 'd3', <[]> ++ ->
    restrict: 'A'
    link: (scope, element, attrs) !->
      console.log "d3 directive"

      svg = d3.select element.0

      trace = ->
        p = [x,y] = d3.mouse element.0
        [c,r] = scope.xy2cr p
        dot = scope.xy2dot p
        console.log "#{d3.event.type} xy=(#{x},#{y}), cr=(#{c},#{r}), dot=(#{dot.p.0},#{dot.p.1})"

      d3Click = (event) ->
        trace!
        if scope.currentTool == 'camera'
          p = [x,y] = d3.mouse element.0
          [c,r] = scope.xy2cr p
          scope.cameras[*] =
            data: [c,r]
          scope.cameraDraw
          scope.makeVisibles!
        scope.$apply!


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
      svg.on "click", d3Click
      # svg.on "mousedown", trace
      # svg.on "mousemove", trace
      # svg.on "mouseup", trace
