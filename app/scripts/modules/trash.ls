'use strict'

angular.module 'trash', []
  .factory 'trash', -> 

    # Responsible for trashing objects so they
    # can be reclaimed if the deletion is undone.

    class Trash
      -> 
        @bin = {}
        @binit = (id, obj) !~> @bin[id] = obj
        @unbin = (id) ~> 
          rv = @bin[id]
          @bin[id] = null
          rv

    new Trash!
