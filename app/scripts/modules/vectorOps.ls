'use strict'

angular.module 'vectorOps', []
  .factory 'vectorOps', -> 

    {fold, zip-with} = require 'prelude-ls'
    
    do
      # add [2,3] [1,2] == [3,5]
      # add [1,2,3] [2,3,4] == [3,5,7]
      # ...
      add: zip-with (+)

      # sub [2,3] [1,2] == [1,1]
      # sub [2,3,4] [1,2,3] == [1,1,1]
      # ...
      sub: zip-with (-)

      # dot [2,3] [1,2] == 8  &&  [2,3] `dot` [1,2] == 8
      # [1,2,1] `dot` [2,3,4] == 12
      dot: (fold (+), 0) . (zip-with (*))

      abs: (v) -> Math.sqrt (@dot v, v)

      # multiply by scalar
      # 3 `times` [1,2] == [3,6]
      # 3 `times` [1,2,3] == [3,6,9]
      times: (a,x) -> x.map (* a)

      unit: (v) -> @times 1/(@abs v), v 

      # 2d cross product: xx [2,3] [1,2] == 1  &&  [2,3] `xx` [1,2] == 1
      xx: (u,v) -> u.0*v.1-u.1*v.0

      # 3d cross product: 
      # xxx [1,0,0] [0,1,0] == [0,0,1]
      # [0,1,0] `xxx` [0,0,1] == [1,0,0]
      xxx: (u,v) -> [u.1*v.2-u.2*v.1, u.2*v.0-u.0*v.2, u.0*v.1-u.1*v.0]
