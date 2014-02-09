'use strict'

angular.module 'illuminateApp' <[ ngRoute mainController]>
  .config <[$routeProvider]> ++ ($routeProvider) ->
    $routeProvider.when '/', {
      templateUrl: 'views/main.html'
      controller: 'MainController'
    }
    .otherwise {
      redirectTo: '/'
    }
