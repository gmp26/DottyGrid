'use strict'

{any, empty, filter, find, flatten, partition, reject, sort-by, tail} = require 'prelude-ls'

angular.module 'dottyGrid' <[lines polygons commandStore]>

  # define the toolset
  .factory 'toolset', -> [

    # * id:'trash'
    #   icon: 'trash-o'
    #   label: 'Delete selected'
    #   tip: 'Click a line or shape to select it, avoiding the dots. Selections show in red'
    #   type: 'danger'
    #   enabled: -> true
    #   active: ""
    #   weight: 5
    # * id:'reset'
    #   icon: 'bolt'
    #   label: 'Clear'
    #   type: 'default'
    #   enabled: true
    #   active: ""
    #   weight: 6
    * id:'rewind'
      icon: 'fast-backward'
      label: ''
      tip: 'Undo all steps'
      type: 'link'
      enabled: -> true
      active: ""
      weight: 7
    * id:'undo'
      icon: 'step-backward'
      label: 'undo'
      tip: 'Undo one step'
      type: 'link'
      enabled: -> true
      active: ""
      weight: 8
    * id:'stop'
      icon: 'pause' 
      label: ''
      tip: 'pause'
      type: 'link'
      enabled: -> true
      active: ""
      weight: 9
    * id:'redo'
      icon: 'step-forward'
      label: 'redo'
      type: 'link'
      tip: 'Redo one step'
      enabled: -> true
      active: ""
      weight: 10
    * id:'play'
      icon: 'fast-forward'
      label: ''
      type: 'link'
      tip: 'Redo all steps'
      enabled: -> true
      active: ""
      weight: 11
  ]

  .controller 'dottyGridController',
  <[
    $scope
    $location
    $routeParams
    $timeout
    commandStore
    toolset
    linesFactory
    polygonsFactory
  ]> ++ (
    $scope,
    $location,
    $routeParams,
    $timeout,
    commandStore,
    toolset,
    linesFactory,
    polygonsFactory
  ) ->

    colCount = 30
    rowCount = 30

    # Pixels from centre of an edge dot to the svg container boundary
    inset = 20

    # Dot separation in pixels
    sep = 30
    scale = 0.75

    # console.log "dottyGridController"

    app = $routeParams.app?.toString!toLowerCase!
    $scope.id = ~~$routeParams.id || 10791
    $scope.backLink = "http://nrich.maths.org/#{$scope.id}"
    $scope.fullScreen = (app and app != "0" and app != "false")

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

    $scope.commands = commandStore

    installPlugin = (plugin, name, active) ->
      plugin.init $scope
      plugin.name = name
      $scope.plugins = [] unless $scope.plugins?
      $scope.plugins[*] = plugin
      plugin.index = $scope.plugins.length - 1
      $scope.toolset = [] unless $scope.toolset?
      $scope.toolset[*] = plugin.tool
      $scope[name] = -> plugin.model!
      if active
        plugin.tool.active = "btn"

      # install default tool button action
      plugin.toolAction ?= (tool) ->
        # select the tool button as currentTool, making it large, and the rest normal
        plugin.tool.active = ""
        $scope.currentTool = tool.id
        $scope.currentPlugin = plugin
        for p in $scope.plugins
          p.tool.active = "btn-sm"
        tool.active = "btn"

    installTools = !->
      installPlugin polygonsFactory, 'polygons', true
      installPlugin linesFactory, 'lines'

      $scope.toolset = sort-by (.weight), ($scope.toolset ++ toolset)

      [$scope.playerTools, $scope.drawTools] = partition ((tool) -> tool.icon in <[
        fast-backward
        step-backward
        pause
        step-forward
        fast-forward
      ]>), $scope.toolset

      [$scope.undoTools, $scope.playerTools] = partition ((tool) -> tool.icon in <[
        step-backward
        step-forward ]>), $scope.playerTools

      for tool in $scope.drawTools
        if tool.id == 'trash'
          break

      cmds = $scope.commands
      for tool in $scope.toolset
        tool.enabled =
          switch tool.icon
          | 'pause' => -> !cmds.stopped
          | 'step-backward', 'fast-backward' => -> cmds.stopped && cmds.pointer > 0
          | 'step-forward', 'fast-forward'  => -> cmds.stopped && cmds.pointer < cmds.stack.length
          | 'trash-o' => ->
            for polygon in $scope.polygons!
              if polygon.selected
                return true
            for line in $scope.lines!
              if line.selected
                return true
            return false
          | otherwise  => -> cmds.stopped

    installTools!

    $scope.deleteSelection = ->
      # delegate to deletion hooks
      newdos = $scope.plugins.map (.deleteSelection!)
      thisObj =
        action: -> for newdo in newdos
          newdo.action.call newdo.thisObj
        undo: -> for newdo in newdos
          newdo.undo.call newdo.thisObj

      commandStore.newdo thisObj, thisObj.action, 'delete', thisObj.undo
      $scope.selectionIsEmpty = true

    $scope.reset = ->
      console.log "clear all"
      #$scope.commandStack = []
      $scope.makeGrid!
      $scope.commands.clear!
      $scope.toolset = []
      installTools!
      $scope.currentTool = 'poly'
      $scope.polyFirst = $scope.polyLast = $scope.lineFirst = false
      # $scope.currentTool = 'poly'
      # $scope.toolset = toolset.concat!
      # for plugin in $scope.plugins
      #   plugin.init $scope


    $scope.toolClick = (tool) ->

      $scope.lastTool = find (.id == $scope.currentTool), $scope.toolset

      # delegate to plugin toolActions
      for plugin in $scope.plugins
        if tool.id == plugin.tool.id
          return plugin.toolAction tool

      if tool.id == 'trash'
        $scope.deleteSelection!
      else if tool.id == 'reset'
        $scope.reset!
      else if tool.id == 'rewind'
        # console.log "rewind"
        $scope.commands.rewind!
      else if tool.id == 'undo'
        # console.log "undo"
        $scope.commands.undo!
      else if tool.id == 'stop'
        # console.log "stop"
        $scope.commands.stop!
      else if tool.id == 'play'
        # console.log "play"
        $scope.commands.play!
      else if tool.id == 'redo'
        # console.log "redo"
        $scope.commands.redo!
      else
        for t in $scope.toolset
          t.active = ""
          tool.active = "btn"
          $scope.currentTool = tool.id

    # initially set the current tool to 'poly'
    $scope.toolClick find (.id == 'poly'), $scope.toolset

    $scope.trace = (col, row) ->
      console.log "(#{col}, #{row})"

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
    $scope.makeGrid = -> 
      rows = for rowIndex from 0 til rowCount
        row = for colIndex from 0 til colCount
          p: [colIndex, rowIndex]
          x: $scope.c2x colIndex
          y: $scope.r2y rowIndex
          first: false
          active: false
        row.y = $scope.r2y rowIndex
        row

      $scope.grid = {rows: rows}

    $scope.makeGrid!

    # var ch
    # ch = 0
    $scope.classHash = (dot) ->
      # if (++ch % 10) == 0
      #   console.log "ch=#{ch}"
      return
        circle: true
        # lit: dot.first
        # "line-lit": dot.lineFirst
        "poly-lit": dot.polyFirst
        "poly-open": dot.polyLast && !dot.polyFirst

    # var dc
    # dc = 0
    $scope.dotClick = (dot) !->
      # if (++dc % 10) == 0
      #   console.log "dc=#{dc}"
      for plugin in $scope.plugins
        if $scope.currentTool == plugin.tool.id && plugin.draw
          #plugin.draw dot
          $scope.commands.newdo plugin, plugin.draw, dot, plugin.undraw
          # console.log $scope.toString!
          return

    # delegate click on object to the object, but stack the command on the way
    #
    # TODO: Toggle does not play well with undo/redo yet. The problem is that
    # if an undo deletes a selected object, that object will be recreated on
    # a future redo. The `thisObject` for the toggle redo will point to the
    # deleted object rather than the new one.
    #
    # Instead of deleting objects, undo/redo should trash them so redo/undo can
    # restore them from trash rather than recreated.
    #
    $scope.toggle = (object) ->
      # console.log "toggle #{object.id}"
      commandStore.newdo object, object.toggle, null, object.toggle

    $scope.toString = -> 
      (for command in $scope.commands.stack
        if command.params == 'delete'
          ''
        else if command.params
          plugin = command.thisObj
          dot = command.params
          "#{plugin.index}-#{dot.p.0}-#{dot.p.1}"
        else
          ''
      ) * '!'

    $scope.getUrl = -> "http://nrich.maths.org/dottyGrid/\#/#{$scope.toString!}?app&id=#{$scope.id}"

    $scope.showLink = ->
      url = $scope.toString!
      $location.path url

    $scope.mailTo = "secondary.nrich@maths.org"
    $scope.mailSubject = "My%20dotty%20grid%20drawing"

    console.log "scope.toString! = " + $scope.toString!

    $scope.mailBody = -> "Here's%20my%20drawing.%0A%0Ahttp://nrich.maths.org/dottyGrid/\#/#{$scope.toString!}?app=1%0A%0A
    I%20think%20it's%20interesting%20because..."

    $scope.polyPoints = (p) ->
      screenPoints = p.data.map $scope.cr2xy
      (flatten screenPoints).join " "

    $scope.polyClass = (p) ->
      "polygon " + if p.selected then "opaque" else ""

    pointHash = (p) -> "#{p.0.toString 16}#{p.1.toString 16}"

    $scope.getDot = (colRow) -> $scope.grid.rows[colRow.1][colRow.0]

    if $routeParams.cmds
      $scope.reset!
      for cmd in ($routeParams.cmds.split '!')
        [index, c, r] = cmd.split '-'
        plugin = $scope.plugins[index]
        commandStore.newdo plugin, plugin.draw, ($scope.getDot [c,r]), plugin.undraw, false
      $timeout (->
        commandStore.pointer = 0
        commandStore.play!), 2000

  
  # .directive 'ngOnce', <[$timeout]> ++ ($timeout) -> {
  #   restrict: 'EA'
  #   priority: 500
  #   transclude: true
  #   template: '<g ng-transclude></g>'
  #   compile: (tElement, tAttrs, transclude) ->
  #     function postLink(scope, iElement, iAttrs, controller)
  #       $timeout scope.$destroy.bind(scope), 0
  # }

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
