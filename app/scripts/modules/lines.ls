'use strict'

#
# simple module that adds line drawing
#
angular.module 'lines', []
  .factory 'lines', -> 

    {} = require 'prelude-ls'
    
    do
      init: ->
        @model = []

      tool:
        id: 'line'
        icon: 'pencil'
        label: 'Draw line'
        type: 'primary'
        enabled: true

      dotA: null

      draw: (dot) ->
        if @model.length > 0 && !@model[*-1].data.p2?
          line = @model[*-1]
        else
          line = data:{}
          @model[*] = line

        if !@dotA #!line.data.p1?
          line.data.p1 = dot.p
          dot.first = true
          @dotA = dot 
        else
          line.data.p2 = dot.p
          @dotA.first = false
          @dotA = null
        @model[*-1] = line



