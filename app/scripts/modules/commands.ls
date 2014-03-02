'use strict'

#
# provides undoable and redoable commands
#
angular.module 'commandStore', []
  .factory 'commandStore', <[$timeout]> ++ ($timeout) ->

    class Command
      (thisObj, action, params, undo) ->
        @action = action
        @thisObj = thisObj
        @params = params
        @undo = undo
        @exec = ~> @action.call @thisObj, @params
        @unexec = ~> @undo.call @thisObj, @params 

    class CommandStore
      ->
        @stopped = true

        @stack = []

        @pointer = 0

        @clear = !~>
          @stack = []
          @pointer = 0

        @timer = null

        @rewind = !~>
          @stopped = false
          @undo!
          if @pointer > 0 and not @stopped
            @timer = $timeout @rewind, 300
          else
            @stopped = true


        @stop = !~>
          @stopped = true
          if @timer
            $timeout.cancel @timer
            @timer = null

        @play = !~>
          @stopped = false
          @redo!
          if @pointer < @stack.length and not @stopped
            @timer = $timeout @play, 300
          else
            @stopped = true


        # add the new command, making it the last entry on the stack
        @newdo = (thisObj, action, params, undo) !~>
          cmd = new Command thisObj, action, params, undo
          @stack[@pointer] = cmd
          @stack.length = ++@pointer
          cmd.exec!

        # undo the last action; keeping it on the stack in case of a future redo
        @undo = !~>
          if @pointer > 0
            cmd = @stack[@pointer = @pointer - 1]
            cmd.unexec!
          console.log "pointer = #{@pointer}"

        # redo the last undo if there was one 
        @redo = !~>
          if @pointer < @stack.length
            cmd = @stack[@pointer]
            @pointer = Math.min @stack.length, (@pointer+1)
            cmd.exec!
          console.log "pointer = #{@pointer}"

    new CommandStore!
