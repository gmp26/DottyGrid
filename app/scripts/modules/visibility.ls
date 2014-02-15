#
# This code is released into the public domain - attribution is appreciated but not required.
# Made by Byron Knoll in 2013.
#
# https://code.google.com/p/visibility-polygon-js/
# Demo: http://www.byronknoll.com/visibility.html
#
# This library can be used to construct a visibility polygon for a set of line segments.
#
# The time complexity of this implementation is O(N log N) (where N is the total number of line segments). This is the optimal time complexity for this problem.
#
# The following three functions should be useful:
#
# 1) VisibilityPolygon.compute(position, segments)
#  Computes a visibility polygon. O(N log N) time complexity.
#  Arguments:
#    position - The location of the observer. Must be completely surrounded by line segments (an easy way to enforce this is to create an outer bounding box).
#    segments - A list of line segments. Each line segment should be a list of two points. Each point should be a list of two coordinates. Line segments can *not* intersect each other (although overlapping vertices is OK).
#  Returns: The visibility polygon (in clockwise vertex order).
#
# 2) VisibilityPolygon.inPolygon(position, polygon)
#  Calculates whether a point is within a polygon. O(N) time complexity.
#  Arguments:
#    position - The point to check: a list of two coordinates.
#    polygon - The polygon to check: a list of points. The polygon can be specified in either clockwise or counterclockwise vertex order.
#  Returns: True if "position" is within the polygon.
#
# 3) VisibilityPolygon.convertToSegments(polygons)
#  Converts the given polygons to list of line segments. O(N) time complexity.
#  Arguments: a list of polygons (in either clockwise or counterclockwise vertex order). Each polygon should be a list of points. Each point should be a list of two coordinates.
#  Returns: a list line segments.
#
# Example code:
#
# var polygons = [];
# polygons.push([[-1,-1],[501,-1],[501,501],[-1,501]]);
# polygons.push([[250,100],[260,140],[240,140]]);
# var segments = VisibilityPolygon.convertToSegments(polygons);
# var position = [10, 10];
# if (VisibilityPolygon.inPolygon(position, polygons[0])) {
#   var visibility = VisibilityPolygon.compute(position, segments);
# }
#
#

'use strict'

angular.module 'visibility', []
  .factory 'VisibilityPolygon', -> do

    compute: (position, segments) ->
      polygon = []
      sorted = @sortPoints position, segments
      mapTable = for i from 0 til segments.length
        -1 

      heap = []
      start =
        position.0 + 1
        position.1

      i = 0

      # while i < segments.length
      #   a1 = @angle(segments[i][0], position)
      #   a2 = @angle(segments[i][1], position)
      #   active = false
      #   active = true  if a1 > -180 and a1 <= 0 and a2 <= 180 and a2 >= 0 and a2 - a1 > 180
      #   active = true  if a2 > -180 and a2 <= 0 and a1 <= 180 and a1 >= 0 and a1 - a2 > 180
      #   @insert i, heap, position, segments, start, mapTable  if active
      #   ++i

      for segment, i in segments
        a1 = @angle segment.0, position
        a2 = @angle segment.1, position
        
        if (a1 > -180 and a1 <= 0 and a2 <= 180 and a2 >= 0 and a2 - a1 > 180) or
          (a2 > -180 and a2 <= 0 and a1 <= 180 and a1 >= 0 and a1 - a2 > 180)
          @insert i, heap, position, segments, start, mapTable

      i = 0

      while i < sorted.length
        extend = false
        shorten = false
        orig = i
        vertex = segments[sorted[i][0]][sorted[i][1]]
        old_segment = heap[0]
        loop
          unless mapTable[sorted[i][0]] is -1
            if sorted[i][0] is old_segment
              extend = true
              vertex = segments[sorted[i][0]][sorted[i][1]]
            @remove mapTable[sorted[i][0]], heap, position, segments, vertex, mapTable
          else
            @insert sorted[i][0], heap, position, segments, vertex, mapTable
            shorten = true  unless heap[0] is old_segment
          ++i
          break  if i is sorted.length
          break unless sorted[i][2] < sorted[orig][2] + @epsilon()
        if extend
          polygon.push vertex
          cur = @intersectLines(segments[heap[0]][0], segments[heap[0]][1], position, vertex)
          polygon.push cur  unless @equal(cur, vertex)
        else if shorten
          polygon.push @intersectLines(segments[old_segment][0], segments[old_segment][1], position, vertex)
          polygon.push @intersectLines(segments[heap[0]][0], segments[heap[0]][1], position, vertex)
      polygon

    inPolygon: (position, polygon) ->
      val = 0
      i = 0

      while i < polygon.length
        val = Math.min(polygon[i][0], val)
        val = Math.min(polygon[i][1], val)
        ++i
      edge = [
        val - 1
        val - 1
      ]
      parity = 0
      i = 0

      while i < polygon.length
        j = i + 1
        j = 0  if j is polygon.length
        if @doLineSegmentsIntersect(edge[0], edge[1], position[0], position[1], polygon[i][0], polygon[i][1], polygon[j][0], polygon[j][1])
          intersect = @intersectLines(edge, position, polygon[i], polygon[j])
          return true  if @equal(position, intersect)
          if @equal(intersect, polygon[i])
            ++parity  if @angle2(position, edge, polygon[j]) < 180
          else if @equal(intersect, polygon[j])
            ++parity  if @angle2(position, edge, polygon[i]) < 180
          else
            ++parity
        ++i
      (parity % 2) isnt 0

    convertToSegments: (polygons) ->
      segments = []
      i = 0

      while i < polygons.length
        j = 0

        while j < polygons[i].length
          k = j + 1
          k = 0  if k is polygons[i].length
          segments.push [
            polygons[i][j]
            polygons[i][k]
          ]
          ++j
        ++i
      segments

    epsilon: ->
      0.0000001

    equal: (a, b) ->
      return true  if Math.abs(a[0] - b[0]) < @epsilon() and Math.abs(a[1] - b[1]) < @epsilon()
      false

    remove: (index, heap, position, segments, destination, mapTable) ->
      mapTable[heap[index]] = -1
      if index is heap.length - 1
        heap.pop()
        return
      heap[index] = heap.pop()
      mapTable[heap[index]] = index
      cur = index
      parent = @parent(cur)
      if cur isnt 0 and @lessThan(heap[cur], heap[parent], position, segments, destination)
        while cur > 0
          parent = @parent(cur)
          break  unless @lessThan(heap[cur], heap[parent], position, segments, destination)
          mapTable[heap[parent]] = cur
          mapTable[heap[cur]] = parent
          temp = heap[cur]
          heap[cur] = heap[parent]
          heap[parent] = temp
          cur = parent
      else
        loop
          left = @child(cur)
          right = left + 1
          if left < heap.length and @lessThan(heap[left], heap[cur], position, segments, destination) and (right is heap.length or @lessThan(heap[left], heap[right], position, segments, destination))
            mapTable[heap[left]] = cur
            mapTable[heap[cur]] = left
            temp = heap[left]
            heap[left] = heap[cur]
            heap[cur] = temp
            cur = left
          else if right < heap.length and @lessThan(heap[right], heap[cur], position, segments, destination)
            mapTable[heap[right]] = cur
            mapTable[heap[cur]] = right
            temp = heap[right]
            heap[right] = heap[cur]
            heap[cur] = temp
            cur = right
          else
            break
      return

    insert: (index, heap, position, segments, destination, mapTable) ->
      intersect = @intersectLines(segments[index][0], segments[index][1], position, destination)
      return  if intersect.length is 0
      cur = heap.length
      heap.push index
      mapTable[index] = cur
      while cur > 0
        parent = @parent(cur)
        break  unless @lessThan(heap[cur], heap[parent], position, segments, destination)
        mapTable[heap[parent]] = cur
        mapTable[heap[cur]] = parent
        temp = heap[cur]
        heap[cur] = heap[parent]
        heap[parent] = temp
        cur = parent
      return

    lessThan: (index1, index2, position, segments, destination) ->
      inter1 = @intersectLines(segments[index1][0], segments[index1][1], position, destination)
      inter2 = @intersectLines(segments[index2][0], segments[index2][1], position, destination)
      unless @equal(inter1, inter2)
        d1 = @distance(inter1, position)
        d2 = @distance(inter2, position)
        return d1 < d2
      end1 = 0
      end1 = 1  if @equal(inter1, segments[index1][0])
      end2 = 0
      end2 = 1  if @equal(inter2, segments[index2][0])
      a1 = @angle2(segments[index1][end1], inter1, position)
      a2 = @angle2(segments[index2][end2], inter2, position)
      if a1 < 180
        return true  if a2 > 180
        return a2 < a1
      a1 < a2

    parent: (index) ->
      Math.floor (index - 1) / 2

    child: (index) ->
      2 * index + 1

    angle2: (a, b, c) ->
      a1 = @angle(a, b)
      a2 = @angle(b, c)
      a3 = a1 - a2
      a3 += 360  if a3 < 0
      a3 -= 360  if a3 > 360
      a3

    sortPoints: (position, segments) ->
      points = new Array(segments.length * 2)
      i = 0

      while i < segments.length
        j = 0

        while j < 2
          a = @angle(segments[i][j], position)
          points[2 * i + j] = [
            i
            j
            a
          ]
          ++j
        ++i
      points.sort (a, b) ->
        a[2] - b[2]

      points

    angle: (a, b) ->
      Math.atan2(b[1] - a[1], b[0] - a[0]) * 180 / Math.PI

    intersectLines: (a1, a2, b1, b2) ->
      ua_t = (b2.0 - b1.0) * (a1.1 - b1.1) - (b2.1 - b1.1) * (a1.0 - b1.0)
      ub_t = (a2.0 - a1.0) * (a1.1 - b1.1) - (a2.1 - a1.1) * (a1.0 - b1.0)
      u_b = (b2.1 - b1.1) * (a2.0 - a1.0) - (b2.0 - b1.0) * (a2.1 - a1.1)
      if u_b == 0
        []
      else
        ua = ua_t / u_b
        ub = ub_t / u_b
        return 
          a1.0 - ua * (a1.0 - a2.0)
          a1.1 - ua * (a1.1 - a2.1)

    distance: (a, b) ->
      ab0 = a.0 - b.0
      ab1 = a.1 - b.1
      ab0 * ab0 + ab1 * ab1

    isOnSegment: (xi, yi, xj, yj, xk, yk) ->
      (xi <= xk or xj <= xk) and (xk <= xi or xk <= xj) and (yi <= yk or yj <= yk) and (yk <= yi or yk <= yj)

    computeDirection: (xi, yi, xj, yj, xk, yk) ->
      a = (xk - xi) * (yj - yi)
      b = (xj - xi) * (yk - yi)
      (if a < b then -1 else (if a > b then 1 else 0))

    doLineSegmentsIntersect: (x1, y1, x2, y2, x3, y3, x4, y4) ->
      d1 = @computeDirection(x3, y3, x4, y4, x1, y1)
      d2 = @computeDirection(x3, y3, x4, y4, x2, y2)
      d3 = @computeDirection(x1, y1, x2, y2, x3, y3)
      d4 = @computeDirection(x1, y1, x2, y2, x4, y4)
      (((d1 > 0 and d2 < 0) or (d1 < 0 and d2 > 0)) and ((d3 > 0 and d4 < 0) or (d3 < 0 and d4 > 0))) or (d1 is 0 and @isOnSegment(x3, y3, x4, y4, x1, y1)) or (d2 is 0 and @isOnSegment(x3, y3, x4, y4, x2, y2)) or (d3 is 0 and @isOnSegment(x1, y1, x2, y2, x3, y3)) or (d4 is 0 and @isOnSegment(x1, y1, x2, y2, x4, y4))