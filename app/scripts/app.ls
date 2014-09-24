'use strict'

angular.module 'DottyApp' <[ ngRoute ngTouch dottyGrid ui.bootstrap ]>
  .config <[$routeProvider]> ++ ($routeProvider) ->

    $routeProvider
    .when '/', do
      templateUrl: 'views/faster.html'
      controller: 'dottyGridController'

    .when '/:cmds?/:app?', do
      templateUrl: 'views/faster.html'
      controller: 'dottyGridController'

    .when '/:cmds?/:id?', do
      templateUrl: 'views/faster.html'
      controller: 'dottyGridController'

    .when '/:cmds?/:app?/&:id?', do
      templateUrl: 'views/faster.html'
      controller: 'dottyGridController'

    .otherwise do
      redirectTo: '/'
