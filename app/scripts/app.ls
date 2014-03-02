'use strict'

angular.module 'DottyApp' <[ ngRoute ngTouch dottyGrid ui.bootstrap ]>
  .config <[$routeProvider]> ++ ($routeProvider) ->
    $routeProvider.when '/', {
      templateUrl: 'views/main.html'
      controller: 'dottyGridController'
    }
    $routeProvider.when '/:cmds', {
      templateUrl: 'views/main.html'
      controller: 'dottyGridController'
    }
    .otherwise {
      redirectTo: '/'
    }
