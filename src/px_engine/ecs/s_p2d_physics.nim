import px_engine/pxd/definition/internal
import px_engine/pxd/m_math
import definition/types

#------------------------------------------------------------------------------------------
# @api phiscis2D shapes
#------------------------------------------------------------------------------------------
proc circle*(api: P2dPhysicsAPI, x,y: f32, radius: f32): CircleShape =
  result.position.x = x
  result.position.y = y
  result.radius     = radius


proc rect*(api: P2dPhysicsAPI, x,y: f32, halfWidth, halfHeight: f32): RectShape =
  result.position.x = x
  result.position.y = y
  result.radius.x   = halfWidth
  result.radius.y   = halfHeight


proc point*(self: var PolygonShape, x,y: f32) =
  self.localVerts.add(vec(x,y))
  self.worldVerts.add(vec(x,y))


proc update*(self: var PolygonShape) =
  let angle = degToRad(self.rotation)
  let cos   = cos(angle)
  let sin   = sin(angle)
  let pivot = self.pivot
  for index, vertex in self.localVerts:
    let rotatedX = vertex.x * cos - vertex.y * -sin
    let rotatedY = vertex.x * -sin + vertex.y * cos
    self.worldVerts[index].x = self.position.x + rotatedX
    self.worldVerts[index].y = self.position.y + rotatedY


proc polygon*(api: P2dPhysicsAPI, x,y: f32; pivotx: f32 = 0.5, pivoty: f32 = 0.5, angle: f32 = 0.0): PolygonShapeBuilder =
  var polygon: PolygonShape
  polygon.position.x  = x
  polygon.position.y  = y
  polygon.pivot.x     = pivotx
  polygon.pivot.y     = pivoty
  polygon.rotation    = angle
  result.resultObject = polygon


proc asRect*(builder: PolygonShapeBuilder, width, height: f32): PolygonShape =
  var poly      = builder.resultObject
  poly.bound.x = width
  poly.bound.y = height
  let w = width
  let h = height
  let x = 0 - poly.pivot.x * width
  let y = 0 - poly.pivot.y * height
  poly.point(x,y)
  poly.point(x+w,y)
  poly.point(x+w,y+h)
  poly.point(x,y+h)
  result = poly
  

proc asRectRound*(builder: PolygonShapeBuilder, width, height: f32, roundness: f32): PolygonShape =
  const segments = 8
  var poly = builder.resultObject
  poly.bound.x = width
  poly.bound.y = height
  let x = 0 - poly.pivot.x * width
  let y = 0 - poly.pivot.y * height
  let w = width
  let h = height
  let angleStep = 90f / segments.float
  let angles  = [180.0,90.0,0,270]
  let x2  = x + w
  let y2  = y + h
  var radius = if w > h: roundness * h * 0.5 else: roundness * w * 0.5
  # positions that forms inner centers of the rect
  let ix = x + radius
  let iy = y + radius
  let iw = w - radius * 2 
  let ih = h - radius * 2
  let ix2 = ix + iw
  let iy2 = iy + ih
  let centers = 
    [vec(ix,iy),vec(ix2,iy),
     vec(ix2,iy2),vec(ix,iy2)]
  #[
                v1 
                 +
                / \ 
               /   \
              +-----+-----
              v2   |c
  ]#
  proc corner(shape: var PolygonShape, indexCorner: int) =
    let a = angles[indexCorner]
    let c = centers[indexCorner]
    for index in 0..<segments:
      let angle1 = a + angleStep * index.float
      let angle2 = angle1 + angleStep
      let v1 = radius * vec(sin(DEG2RAD * angle1), cos(DEG2RAD * angle1))
      let v2 = radius * vec(sin(DEG2RAD * angle2), cos(DEG2RAD * angle2))
      shape.point(c.x + v1.x, c.y + v1.y)
      shape.point(c.x + v2.x, c.y + v2.y)
  block body:
    poly.corner(0)
    poly.point(ix,y)
    poly.point(ix2,y)
    poly.corner(1)
    poly.point(x2,iy)
    poly.point(x2,iy2)
    poly.corner(2)
    poly.point(ix2,y2)
    poly.point(ix,y2)
    poly.corner(3)
    poly.point(x,iy2)
    poly.point(x,iy)
  result = poly


#------------------------------------------------------------------------------------------
# @api phiscis2D overlap algorythms
#------------------------------------------------------------------------------------------
proc projectPolygon(axis: Vec2, polygon: var PolygonShape): tuple[min, max: f32] {.inline.} =
  var minProjection = dot2(axis, polygon.worldVerts[0].xy)
  var maxProjection = minProjection
  for i in 1..<polygon.worldVerts.len:
    let projection = dot2(axis, polygon.worldVerts[i])
    if projection < minProjection:
      minProjection = projection
    elif projection > maxProjection:
      maxProjection = projection
  return (minProjection, maxProjection)


proc projectAABB(axis: Vec2, shape: var RectShape): tuple[min,max:f32] {.inline.} =
  var vertices: array[4, Vec2]
  var minProjection: f32 = f32.high
  var maxProjection: f32 = f32.low
  vertices[0] = vec(shape.position.x-shape.radius.x, shape.position.y-shape.radius.y)
  vertices[1] = vec(shape.position.x+shape.radius.x, shape.position.y-shape.radius.y)
  vertices[2] = vec(shape.position.x+shape.radius.x, shape.position.y+shape.radius.y)
  vertices[3] = vec(shape.position.x-shape.radius.x, shape.position.y+shape.radius.y)
  for vertex in vertices:
    let projection = dot2(axis, vertex)
    minProjection = min(minProjection, projection)
    maxProjection = m_math.max(maxProjection, projection)
  return (min: minProjection, max: maxProjection)


proc projectCircle(axis: Vec2, circle: var CircleShape): tuple[min, max: f32] =
  let direction = axis.normalized
  let center    = circle.position
  let distance  = direction * circle.radius
  return (min: dot2(axis, center - distance), max: dot2(axis, center + distance))


proc overlapIntervals(a, b: tuple[min, max: f32]): bool {.inline.} =
  return a.min <= b.max and b.min <= a.max


proc findClosestPolygonPoint(circleCenter: Vec3, polygon: var PolygonShape): int {.inline.} =
  result = -1
  var minDistance = float.high
  for i,v in polygon.worldVerts.mpairs:
    var distance = distanceSquared(v,circleCenter)
    if distance < minDistance:
      minDistance = distance
      result = i


proc aabb(a,b: var RectShape): bool {.inline.} =
  return abs(a.position.x-b.position.x) < (a.radius.x+b.radius.x) and
         abs(a.position.y-b.position.y) < (a.radius.y+b.radius.y)


proc circleAABBCollision(a: var CircleShape, b: var RectShape): bool {.inline.} =
  # Find closest point to the circle
  let closestX = m_math.max(b.position.x-b.radius.x, min(a.position.x, b.position.x + b.radius.x))
  let closestY = m_math.max(b.position.y-b.radius.y, min(a.position.y, b.position.y + b.radius.y))
  let distanceX = closestX - a.position.x
  let distanceY = closestY - a.position.y
  let distance  = pow(distanceX,2) + pow(distanceY,2)
  result = distance <= pow(a.radius, 2)


proc circleCircleCollision(a, b: var CircleShape): bool {.inline.} =
  let maxDist = a.radius + b.radius;
  let dx = b.position.x - a.position.x
  let dy = b.position.y - a.position.y
  return (dx*dx+dy*dy) <= maxDist * maxDist


proc polyPolyCollision(a,b: var PolygonShape): bool {.inline.} =
  for vertexId in 0..<a.worldVerts.len:
    let nextVertexId = (vertexId+1) mod a.worldVerts.len
    let x = a.worldVerts[vertexId].x
    let y = a.worldVerts[vertexId].y 
    let xx = a.worldVerts[nextVertexId].x
    let yy = a.worldVerts[nextVertexId].y
    let edge = vec(xx - x, yy - y)
    let axis = getNormal(edge)
    let projectionA = projectPolygon(axis, a)
    let projectionB = projectPolygon(axis, b)
    if not overlapIntervals(projectionA, projectionB):
      return false
  for vertexId in 0..<b.worldVerts.len:
    let nextVertexId = (vertexId+1) mod b.worldVerts.len
    let x = b.worldVerts[vertexId].x
    let y = b.worldVerts[vertexId].y
    let xx = b.worldVerts[nextVertexId].x
    let yy = b.worldVerts[nextVertexId].y
    let edge = vec(xx - x, yy - y)
    let axis = getNormal(edge)
    let projectionA = projectPolygon(axis, a)
    let projectionB = projectPolygon(axis, b)
    if not overlapIntervals(projectionA, projectionB):
      return false
  return true


proc polyAABBCollision(a: var PolygonShape, b: var RectShape): bool {.inline.} =
  for vertexId in 0..<a.worldVerts.len:
    let nextVertexId = (vertexId+1) mod a.worldVerts.len
    let x = a.worldVerts[vertexId].x
    let y = a.worldVerts[vertexId].y 
    let xx = a.worldVerts[nextVertexId].x
    let yy = a.worldVerts[nextVertexId].y
    let edge = vec(xx - x, yy - y)
    let axis = getNormal(edge)
    let projectionA = projectPolygon(axis, a)
    let projectionB = projectAABB(axis, b)
    if not overlapIntervals(projectionA, projectionB):
      return false
  return true


proc polyCircleCollision(a: var PolygonShape, b: var CircleShape): bool {.inline.} =
  for vertexId in 0..<a.worldVerts.len:
    let nextVertexId = (vertexId+1) mod a.worldVerts.len
    let x  = a.worldVerts[vertexId].x
    let y  = a.worldVerts[vertexId].y 
    let xx = a.worldVerts[nextVertexId].x
    let yy = a.worldVerts[nextVertexId].y
    let edge = vec(xx - x, yy - y)
    let axis = getNormal(edge)
    let projectionA = projectPolygon(axis, a)
    let projectionB = projectCircle(axis, b)
    if not overlapIntervals(projectionA, projectionB):
      return false
  var vertexId = findClosestPolygonPoint(b.position,a)
  let cp = a.worldVerts[vertexId]
  var axis = (cp - b.position).normalized
  let projectionA = projectPolygon(axis.xy, a)
  let projectionB = projectCircle(axis.xy, b)
  if not overlapIntervals(projectionA, projectionB):
    return false
  return true


proc overlap*[T,TT: RectShape | CircleShape | PolygonShape](api: P2dPhysicsAPI, shape1: var T, shape2: var TT): bool =
  when shape1 is RectShape and shape2 is CircleShape:
    return circleAABBCollision(shape2,shape1)
  elif shape1 is CircleShape and shape2 is RectShape:
    return circleAABBCollision(shape1,shape2)
  elif shape1 is PolygonShape and shape2 is RectShape:
    return polyAABBCollision(shape1, shape2)
  elif shape1 is RectShape and shape2 is PolygonShape:
    return polyAABBCollision(shape2, shape1)
  elif shape1 is PolygonShape and shape2 is CircleShape:
    return polyCircleCollision(shape1, shape2)
  elif shape1 is CircleShape and shape2 is PolygonShape:
    return polyCircleCollision(shape2, shape1)
  elif shape1 is RectShape and shape2 is RectShape:
    return aabb(shape1,shape2)
  elif shape1 is CircleShape and shape2 is CircleShape:
    return circleCircleCollision(shape1,shape2)
  elif shape1 is PolygonShape and shape2 is PolygonShape:
    return polyPolyCollision(shape1, shape2)


proc inside*(api: P2dPhysicsAPI,shape: var CircleShape, point: Vec): bool =
  let dx = point.x-shape.position.x
  let dy = point.y-shape.position.y
  return (dx*dx+dy*dy) <= shape.radius * shape.radius


proc inside*(api: P2dPhysicsAPI,shape: var RectShape, point: Vec): bool =
  let minX = shape.position.x - shape.radius.x
  let maxX = shape.position.x + shape.radius.x
  let minY = shape.position.y - shape.radius.y
  let maxY = shape.position.y + shape.radius.y
  return point.x >= minX and point.x <= maxX and point.y >= minY and point.y <= maxY


proc inside*(api: P2dPhysicsAPI,shape: var PolygonShape, point: Vec): bool {.inline.} =
  let len = shape.worldVerts.len
  var isInside = false
  var indexn = len - 1
  for index in 0..<len:
    let v1 = shape.worldVerts[index].addr
    let v2 = shape.worldVerts[indexn].addr
    if(((v1.y>point.y)!=(v2.y>point.y)) and (point.x < (v2.x-v1.x)*(point.y-v1.y)/(v2.y-v1.y)+v1.x)):
      isInside = not isInside
    indexn = index
  return isInside


  # if polygon1.shapeKind == Shape2DKind.Circle and polygon2.shapeKind == Shape2DKind.Circle:
  #   return circleCircleCollision(polygon1,polygon2)
  # elif polygon1.shapeKind == Shape2DKind.Rectangle and polygon2.shapeKind == Shape2DKind.Rectangle:
  #   return rectRectCollision(polygon1,polygon2)
  # else:
  #   if polygon1.shapeKind == Shape2DKind.Rectangle:
  #     return rectCircleCollision(polygon1, polygon2)
  #   else:
  #     return rectCircleCollision(polygon2, polygon1)


#------------------------------------------------------------------------------------------
# @api dump
#------------------------------------------------------------------------------------------
# future
proc crossProduct(a, b, c: Vec3): float =
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)


proc sameSide(p1, p2, a, b: Vec3): bool =
  crossProduct(b, a, p1) * crossProduct(b, a, p2) > 0.0


proc pointInTriangle(p,a,b,c: Vec3): bool {.inline.} =
  if sameSide(p,a, b,c) and sameSide(p,b, a,c) and sameSide(p,c, a,b): return true
  return false



