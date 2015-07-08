'use strict'

{any, empty, filter, find, flatten, partition, reject, sort-by, tail, drop} = require 'prelude-ls'

angular.module 'dottyGrid' <[orangeDots blueDots redDots lines polygons commandStore]>

  # define the toolset
  .factory 'toolset', -> [

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
  <[$scope $location $routeParams $timeout commandStore toolset orangeDotsFactory blueDotsFactory redDotsFactory linesFactory polygonsFactory ]> ++ (
    $scope,
    $location,
    $routeParams,
    $timeout,
    commandStore,
    toolset,
    orangeDotsFactory,
    blueDotsFactory,
    redDotsFactory,
    linesFactory,
    polygonsFactory
  ) ->

    # colCount = 30
    # rowCount = 30

    # # Pixels from centre of an edge dot to the svg container boundary
    # inset = 20

    # # Dot separation in pixels
    # sep = 30
    # $scope.scale = 0.75


    colCount = 17
    rowCount = 20

    # Pixels from centre of an edge dot to the svg container boundary
    inset = 20

    # Dot separation in pixels
    sep = 40
    $scope.scale = 1

    # console.log "dottyGridController"

    app = $routeParams.app?.toString!toLowerCase!
    $scope.id = ~~$routeParams.id || 10791
    if ($routeParams.cmds?.indexOf "iso-") == 0
      $scope.iso = true
      $routeParams.cmds = drop 4 $routeParams.cmds
    else
      $scope.iso = false

    console.log "routeParams"
    console.debug $routeParams
    # $scope.backLink = "http://nrich.maths.org/#{$scope.id}"

    $scope.backLink = if (window.location != window.parent.location) then document.referrer else document.location

    $scope.fullScreen = (app and app != "0" and app != "false") || !$routeParams.id?

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
      $scope.plugins = []
      $scope.toolset = []
      installPlugin polygonsFactory, 'polygons', true
      installPlugin linesFactory, 'lines'
      installPlugin orangeDotsFactory, 'orangeDots'
      installPlugin blueDotsFactory, 'blueDots'
      installPlugin redDotsFactory, 'redDots'

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

      cmds = $scope.commands
      for tool in $scope.toolset
        tool.enabled =
          switch tool.icon
          | 'pause' => -> !cmds.stopped
          | 'step-backward', 'fast-backward' => -> cmds.stopped && cmds.pointer > 0
          | 'step-forward', 'fast-forward'  => -> cmds.stopped && cmds.pointer < cmds.stack.length
          | otherwise  => -> cmds.stopped

    installTools!

    $scope.reset = (iso) ->
      # change iso if explicitly selected
      if arguments.length == 1
        $scope.iso = iso

      $scope.coordTransforms!
      #$scope.commandStack = []
      installTools!
      $scope.makeGrid!
      $scope.commands.clear!
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

      if tool.id == 'reset'
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
      return "scale(#{$scope.scale})"

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

    # $scope.c2x = d3.scale.linear!
    # .domain [0,colCount-1]
    # .range [inset, colCount*sep]

    oddy = d3.scale.linear!
             .domain [0,colCount-1]
             .range [inset + sep/2, colCount*sep + sep/2]

    ioddy = oddy.invert

    eveny = d3.scale.linear!
             .domain [0,colCount-1]
             .range [inset, colCount*sep]

    ieveny = eveny.invert

    $scope.coordTransforms = ->
      $scope.c2xIso = (y) ->
        if $scope.iso && y && (y % 2 == 1) then oddy else eveny

      $scope.x2cIso = (y) ->
        r = Math.round($scope.y2r y)
        if ($scope.iso && r % 2 == 1) then ioddy else ieveny

      # $scope.x2cIso = (y) -> ($scope.c2xIso y).invert
      $scope.x2CIso = (y) -> ((x) -> Math.round (($scope.x2cIso y) x))

      $scope.r2y = d3.scale.linear!
        .domain [0,rowCount-1]
        .range [rowCount*sep*(if $scope.iso then Math.sqrt(3)/2 else 1), inset]

      $scope.y2r = $scope.r2y.invert
      $scope.y2R = (y) -> Math.round $scope.y2r y

      $scope.cr2xyIso = (p) ->
        * ($scope.c2xIso p.1) p.0
          $scope.r2y p.1

      $scope.xy2crIso = (p) ->
        * ($scope.x2cIso p.1) p.0
          $scope.y2r p.1

      $scope.xy2dot = (p) ->
        col = ($scope.x2CIso p.1) p.0
        row = $scope.y2R p.1
        $scope.grid.rows[row][col]

      $scope.svgWidth = ->
        $scope.scale * (inset + ($scope.c2xIso 2) colCount-(if $scope.iso then 0.5 else 1))
      $scope.svgHeight = -> $scope.scale * (inset + $scope.r2y 0)

    $scope.coordTransforms!

    #
    # dots in the dotty grid
    #
    $scope.makeGrid = ->
      rows = for rowIndex from 0 til rowCount
        row = for colIndex from 0 til colCount
          p: [colIndex, rowIndex]
          x: ($scope.c2xIso rowIndex) colIndex
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

    $scope.toString = ->
      "#{if $scope.iso then 'iso-' else ''}" ++ (
        (for command in $scope.commands.stack
          if command.params
            plugin = command.thisObj
            dot = command.params
            "#{plugin.index}-#{dot.p.0}-#{dot.p.1}"
          else
            ''
        ) * '!')

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
      screenPoints = p.data.map $scope.cr2xyIso
      (flatten screenPoints).join " "

    $scope.polyClass = (p) ->
      "polygon " + if p.selected then "opaque" else ""

    pointHash = (p) -> "#{p.0.toString 16}#{p.1.toString 16}"

    $scope.getDot = (colRow) -> $scope.grid.rows[colRow.1][colRow.0]

    if $routeParams.cmds
      $scope.reset!
      for cmd in ($routeParams.cmds.split '!')
        continue if cmd == ""
        [index, c, r] = cmd.split '-'
        continue unless 0 <= index <= 4 and 0 <= r <= rowCount and 0 <= c <= colCount
        plugin = $scope.plugins[index]
        commandStore.newdo plugin, plugin.draw, ($scope.getDot [c,r]), plugin.undraw, false
      $timeout (->
        commandStore.pointer = 0
        commandStore.play!), 2000

  .directive 'd3', <[]> ++ ->
    restrict: 'A'
    link: (scope, element, attrs) !->
      # console.log "d3 directive"

      svg = d3.select element.0
      xy2dot = (p) ->
        p.0 = p.0 / scope.scale
        p.1 = p.1 / scope.scale
        [c,r] = scope.xy2crIso p
        cC = c - Math.round(c)
        rR = r - Math.round(r)
        console.log "[c,r] = #{c}, #{r}"
        if (Math.sqrt (cC*cC + rR*rR)) < 20
          dot = scope.xy2dot p
        else
          null

      trace = ->
        p = [x,y] = d3.mouse element.0
        [c,r] = scope.xy2crIso p
        dot = scope.xy2dot p
        # console.log "#{d3.event.type} xy=(#{x},#{y}), cr=(#{c},#{r}), dot=(#{dot.p.0},#{dot.p.1})"

      d3Click = (event) ->
        p = [x,y] = d3.mouse element.0
        dot = xy2dot p

        if dot
          scope.dotClick dot

        scope.$apply!

      svg.on "click", d3Click


  .directive 'ngOnce', <[$timeout]> ++ ($timeout) -> {
    restrict: 'EA'
    priority: 500
    transclude: true
    template: '<g ng-transclude></g>'
    compile: (tElement, tAttrs, transclude) ->
      function postLink(scope, iElement, iAttrs, controller)
        $timeout scope.$destroy.bind(scope), 0
  }

