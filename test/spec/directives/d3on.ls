'use strict'

describe 'Directive: d3on', (_) ->

  # load the directive's module
  beforeEach module 'd3onDirective'

  var $rootScope
  var $scope
  var $compile

  beforeEach inject (_$compile_, _$rootScope_) ->
    $rootScope := _$rootScope_
    $scope := $rootScope.$new!
    $compile := _$compile_

  it 'should make hidden element visible', ->
    element = angular.element '<d3on></d3on>'
    element = $compile(element) $scope
    expect element.text! .toBe 'this is the d3on directive'
