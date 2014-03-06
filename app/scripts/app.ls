'use strict'

angular.module 'DottyApp' <[ ngRoute ngTouch dottyGrid ui.bootstrap ]>
  .config <[$routeProvider]> ++ ($routeProvider) ->
    $routeProvider.when '/', {
      templateUrl: 'views/faster.html'
      controller: 'dottyGridController'
    }
    $routeProvider.when '/:cmds/:app?/:id?', {
      templateUrl: 'views/faster.html'
      controller: 'dottyGridController'
    }
    .otherwise {
      redirectTo: '/'
    }
