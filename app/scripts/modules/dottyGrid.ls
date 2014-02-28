'use strict'

{any, empty, filter, find, flatten, reject, sort-by, tail} = require 'prelude-ls'

angular.module 'dottyGrid' <[lines polygons]>

  # define the toolset
  .factory 'toolset', -> [

    * id:'trash'
      icon: 'trash-o'
      label: 'Delete selected'
      type: 'danger'
      enabled: true
      active: ""
      weight: 5
    * id:'reset'
      icon: 'bolt'
      label: 'Clear'
      type: 'default'
      enabled: true
      active: ""
      weight: 6
    * id:'undo'
      icon: 'reply'
      label: 'Undo'
      type: 'info'
      enabled: true
      active: ""
      weight: 7
    # * id:'link'
    #   icon: 'chain'
    #   label: 'Link'
    #   type: 'link'
    #   enabled: true
    #   active: ""
    #   weight: 8
  ]

  .controller 'dottyGridController',
  <[
    $scope
    toolset
    linesFactory
    polygonsFactory
  ]> ++ (
    $scope,
    toolset,
    linesFactory,
    polygonsFactory
  ) ->

    console.log "dottyGridController"

    $scope.fills = [
      'red'
      'blue'
      'green'
      'orange'
      'purple'
      'lightblue'
      'pink'
      'black'
      'magenta'
      'darkcyan'
    ]

    # for the undo and link buttons
    $scope.commandStack = []

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
        $scope.currentPlugin = plugin
        for t in $scope.toolset
          t.active = ""
        tool.active = "btn-lg"
        true

    installPlugin polygonsFactory, 'polygons', true
    installPlugin linesFactory, 'lines'
    $scope.toolset = sort-by (.weight), toolset

    $scope.deleteSelection = ->
      # delegate to deletion hooks
      plugins.map (.deleteSelection!)

    $scope.clearAll = ->
      console.log "clear all"
      for plugin in plugins
        plugin.init $scope

    $scope.undo = ->
      console.log "undo"
      if $scope.commandStack.length > 0
        lastCommand = $scope.commandStack.pop!
        lastCommand.undo.apply lastCommand.params.0, (tail lastCommand.params)

    $scope.toolClick = (tool) ->

      $scope.lastTool = find (.id == $scope.currentTool), toolset

      # delegate to plugin toolActions
      for plugin in plugins
        if tool.id == plugin.tool.id
          return plugin.toolAction tool

      if tool.id == 'trash'
        $scope.deleteSelection!
      else if tool.id == 'reset'
        $scope.clearAll!
      else if tool.id == 'undo'
        $scope.undo!

      else
        for t in $scope.toolset
          t.active = ""
          tool.active = "btn-lg"
          $scope.currentTool = tool.id

    # initiall set the current tool to 'poly'
    $scope.toolClick find (.id == 'poly'), toolset

    $scope.trace = (col, row) ->
      console.log "(#{col}, #{row})"

    colCount = 30
    rowCount = 30

    # Pixels from centre of an edge dot to the svg container boundary
    inset = 20

    # Dot separation in pixels
    sep = 30
    scale = 0.75

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
      "line-lit": dot.lineFirst
      "poly-lit": dot.polyFirst

    $scope.dotClick = (dot) ->
      for plugin in plugins
        if $scope.currentTool == plugin.tool.id && plugin.draw
          plugin.draw dot
          $scope.commandStack[*] = {action: plugin.draw, params: [plugin, dot], undo:plugin.undraw}
          return

    $scope.polyPoints = (p) ->
      screenPoints = p.data.map $scope.cr2xy
      (flatten screenPoints).join " "

    $scope.polyClass = (p) ->
      "polygon " + if p.selected then "opaque" else ""

    pointHash = (p) -> "#{p.0.toString 16}#{p.1.toString 16}"

    $scope.polyToggle = (p) -> p.selected = !p.selected

  .directive 'd3', <[]> ++ ->
    restrict: 'A'
    link: (scope, element, attrs) !->
      # console.log "d3 directive"

      svg = d3.select element.0

      trace = ->
        p = [x,y] = d3.mouse element.0
        [c,r] = scope.xy2cr p
        dot = scope.xy2dot p
        # console.log "#{d3.event.type} xy=(#{x},#{y}), cr=(#{c},#{r}), dot=(#{dot.p.0},#{dot.p.1})"

      d3Click = (event) ->
        trace!
        if scope.currentTool == 'camera'
          p = [x,y] = d3.mouse element.0
          [c,r] = scope.xy2cr p
          scope.cameras[*] =
            data: [c,r]
          scope.cameraDraw
          scope.makeVisibles!

          # switch back to previous tool immediately
          scope.toolClick scope.lastTool

        scope.$apply!

      svg.on "click", d3Click
