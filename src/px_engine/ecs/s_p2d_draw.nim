import std/unicode
import px_engine/pxd/definition/internal
import e_p2d


var render2D     = pxd.engine.render2D


#------------------------------------------------------------------------------------------
# @api pixel
#------------------------------------------------------------------------------------------
proc pixel*(api: P2DrawAPI, x,y,z: f32; size: f32 = 1.px; color: Color = cwhite) =
  const indices  = 0
  const vertices = 6
  r2d.draw(render2D.renderer, indices, vertices, R2D_GEOMETRY):
    r2d.color(color)
    r2d.texture(render2D.texWhiteId)
    r2d.vertex(x     ,y     ,z) #A:0
    r2d.vertex(x+size,y     ,z) #B:1
    r2d.vertex(x+size,y+size,z) #C:2
    r2d.vertex(x     ,y+size,z) #D:3
    r2d.vertex(x     ,y     ,z) #A:0
    r2d.vertex(x+size,y+size,z) #C:2


proc pixel*(api: P2DrawAPI, x,y: f32; size: f32 = 1.px; color: Color = cwhite) =
  api.pixel(x,y,0,size,color)


#------------------------------------------------------------------------------------------
# @api line
#------------------------------------------------------------------------------------------
proc line(p1, p2: Vec2, thickness: f32, col: Color = cwhite) {.inline.} =
  const indices = 0
  const vertices = 6
  let radius = r2d.getLineRadius(p1,p2,thickness)
  r2d.draw(render2D.renderer, indices, vertices, R2D_GEOMETRY):
    r2d.color(col)
    r2d.texture(render2D.texWhiteId)
    r2d.vertex(p1.x-radius.x,p1.y-radius.y,0) #A-0
    r2d.vertex(p1.x+radius.x,p1.y+radius.y,0) #B-1
    r2d.vertex(p2.x+radius.x,p2.y+radius.y,0) #C-2
    r2d.vertex(p2.x-radius.x,p2.y-radius.y,0) #D-3
    r2d.vertex(p1.x-radius.x,p1.y-radius.y,0) #A-0
    r2d.vertex(p2.x+radius.x,p2.y+radius.y,0) #C-2


proc line*(api: P2DrawAPI, p1, p2: Vec3, thickness: f32, color: Color = cwhite) =
  line(p1, p2, thickness,  color)


proc line*(api: P2DrawAPI, x,y:f32, xx,yy: f32, thickness: f32, color: Color = cwhite) =
  line(vec(x,y), vec(xx,yy), thickness,  color)


#------------------------------------------------------------------------------------------
# @api circle
#------------------------------------------------------------------------------------------
proc circleSector*(api: P2DrawAPI, x,y,z: f32, radius: f32, angleBegin: f32, angleEnd: f32, segments: i32, color: Color = cwhite) =
  const indices  = 0
  let angleStep  = (angleEnd-angleBegin) / f32(segments)
  var angle      = angleBegin
  let vertices   = segments * 3
  r2d.draw(render2D.renderer, indices, vertices, R2D_GEOMETRY):
    #[
                  v2  v1
                   +--+
                  / \ | 
                 /   \|
                +-----+-----
                      |center
                      |
    ]#
    r2d.color(color)
    r2d.texture(render2D.texWhiteId)
    for index in 0..<segments:
      let v1 = radius * vec(sin(DEG2RAD * (angle + angleStep + angleStep)), cos(DEG2RAD * (angle + angleStep + angleStep)))
      let v2 = radius * vec(sin(DEG2RAD * (angle + angleStep)), cos(DEG2RAD * (angle + angleStep)))
      r2d.vertex(x+v1.x,y+v1.y,z)
      r2d.vertex(x+v2.x,y+v2.y,z)
      r2d.vertex(x, y,z)
      angle += angleStep


proc circle*(api: P2DrawAPI, x,y,z: f32, radius: f32, segments: i32, color: Color = cwhite) =
  api.circleSector(x, y, z, radius, 0f, 360f, segments, color)


proc circle*(api: P2DrawAPI, x,y,z: f32, radius: f32, color: Color = cwhite) =
  const segments = 24
  api.circleSector(x, y, z, radius, 0f, 360f, segments, color)


proc circleSectorLine*(api: P2DrawAPI, x,y,z: f32; radius: f32, thickness: f32, segments: i32, angleBegin: f32, angleEnd: f32, color: Color = cwhite): tuple[v1,v2: Vec] {.discardable.} =
  const indices = 0
  let angleStep  = (angleEnd-angleBegin)*DEG2RAD / f32(segments)
  var cosBegin = cos(angleBegin)
  var sinBegin = sin(angleBegin)
  let cosStep  = cos(angleStep)
  let sinStep  = sin(angleStep)
  let cx = x
  let cy = y
  let radius1 = radius - thickness / 2.0
  let radius2 = radius + thickness / 2.0
  let vertices = segments * 6
  r2d.draw(render2D.renderer, indices, vertices, R2D_GEOMETRY):
    r2d.color(color)
    r2d.texture(render2D.texWhiteId)
    for i in 0..<segments:
      let cosEnd = cosBegin * cosStep - sinBegin * sinStep
      let sinEnd = cosBegin * sinStep + sinBegin * cosStep
      let x1 = cx + radius1 * cosBegin
      let y1 = cy + radius1 * sinBegin
      let x2 = cx + radius1 * cosEnd
      let y2 = cy + radius1 * sinEnd
      let x3 = cx + radius2 * cosEnd
      let y3 = cy + radius2 * sinEnd
      let x4 = cx + radius2 * cosBegin
      let y4 = cy + radius2 * sinBegin
      r2d.vertex(x1,y1,z)
      r2d.vertex(x4,y4,z)
      r2d.vertex(x3,y3,z)
      r2d.vertex(x1,y1,z)
      r2d.vertex(x3,y3,z)
      r2d.vertex(x2,y2,z)
      cosBegin = cosEnd
      sinBegin = sinEnd


proc circleLine*(api: P2DrawAPI, x,y,z: f32, radius: f32, thickness: f32, color: Color = cwhite) =
  const segments = 24
  api.circleSectorLine(x,y,z, radius, thickness, segments, 0f, 360f, cWhite)


proc circleLine*(api: P2DrawAPI, x,y,z: f32, radius: f32, thickness: f32, segments: i32, color: Color) =
  api.circleSectorLine(x,y,z, radius, thickness, segments, 0f, 360f, color)


proc circle*(api: P2DrawAPI, x,y: f32, radius: f32, segments: i32, color: Color = cwhite) =
  api.circleSector(x, y, 0, radius, 0f, 360f, segments, color)


proc circle*(api: P2DrawAPI, x,y: f32, radius: f32, color: Color = cwhite) =
  const segments = 24
  api.circleSector(x, y, 0, radius, 0f, 360f, segments, color)


proc circleLine*(api: P2DrawAPI, x,y: f32, radius: f32, thickness: f32, color: Color = cwhite) =
  const segments = 24
  api.circleSectorLine(x,y,0, radius, thickness, segments, 0f, 360f, color)


proc circleLine*(api: P2DrawAPI, x,y: f32, radius: f32, thickness: f32, segments: i32, color: Color) =
  api.circleSectorLine(x,y,0, radius, thickness, segments, 0f, 360f, color)


#------------------------------------------------------------------------------------------
# @api rectangle
#------------------------------------------------------------------------------------------
proc rect*(api: P2DrawAPI, x,y,z: f32; w,h: f32; color: Color = cwhite) =
  ## Draw a rectangle.
  ## Renderer: ShapeRender.
  const indices  = 0
  const vertices = 6
  r2d.draw(render2D.renderer, indices, vertices, R2D_GEOMETRY):
    r2d.color(color)
    r2d.texture(render2D.texWhiteId)
    r2d.vertex(x  ,y  ,z) #A:0
    r2d.vertex(x+w,y  ,z) #B:1
    r2d.vertex(x+w,y+h,z) #C:2
    r2d.vertex(x  ,y+h,z) #D:3
    r2d.vertex(x  ,y  ,z) #A:0
    r2d.vertex(x+w,y+h,z) #C:2


proc rect*(api: P2DrawAPI, x,y,z: f32; w,h: f32; cx,cy: f32, angle: f32, color: Color = cwhite) =
  ## Draw a rectangle.
  ## Renderer: ShapeRender.
  const indices = 0
  const vertices = 6
  let angle = angle * DEG2RAD
  let cos = m_math.cos(angle)
  let sin = m_math.sin(angle)
  let x = x - cx * w
  let y = y - cy * h
  let ox = x + cx * w
  let oy = y + cy * h
  r2d.draw(render2D.renderer, indices, vertices, R2D_GEOMETRY):
    r2d.color(color)
    r2d.texture(render2D.texWhiteId)
    r2d.vertexr(x  ,y  ,z, ox, oy, cos, sin) #A:0
    r2d.vertexr(x+w,y  ,z, ox, oy, cos, sin) #B:1
    r2d.vertexr(x+w,y+h,z, ox, oy, cos, sin) #C:2
    r2d.vertexr(x  ,y+h,z, ox, oy, cos, sin) #D:3
    r2d.vertexr(x  ,y  ,z, ox, oy, cos, sin) #A:0
    r2d.vertexr(x+w,y+h,z, ox, oy, cos, sin) #C:2


proc rectRound*(api: P2DrawAPI, x,y,z: f32, w,h: f32, roundness: f32, color: Color = cwhite) =
  const indices  = 0
  const segments = 8
  const vertices = 30 + 4 * segments * 3
  let x2 = x + w
  let y2 = y + h
  # positions that forms inner centers of the rect
  let radius = if w > h: roundness * h * 0.5 else: roundness * w * 0.5
  let ix: f32 = x + radius
  let iy: f32 = y + radius
  let iw: f32 = w - radius * 2 
  let ih: f32 = h - radius * 2
  let ix2: f32 = ix + iw
  let iy2: f32 = iy + ih
  let pt = [
    vec(ix,iy2),
    vec(ix,iy),
    vec(ix2,iy),
    vec(ix2,iy2),
    vec(ix,y),
    vec(ix2,y),
    vec(x2,iy),
    vec(x2,iy2),
    vec(ix,y2),
    vec(ix2,y2),
    vec(x,iy2),
    vec(x,iy)
  ]
  block body:
    r2d.draw(render2D.renderer, indices, vertices, R2D_GEOMETRY):
      r2d.color(color)
      r2d.texture(render2D.texWhiteId)
      # center
      r2d.vertex(pt[0])
      r2d.vertex(pt[1])
      r2d.vertex(pt[2])
      r2d.vertex(pt[3])
      r2d.vertex(pt[0])
      r2d.vertex(pt[2])
      # down
      r2d.vertex(pt[1])
      r2d.vertex(pt[4])
      r2d.vertex(pt[5])
      r2d.vertex(pt[2])
      r2d.vertex(pt[1])
      r2d.vertex(pt[5])
      # # right
      r2d.vertex(pt[3])
      r2d.vertex(pt[2])
      r2d.vertex(pt[6])
      r2d.vertex(pt[7])
      r2d.vertex(pt[3])
      r2d.vertex(pt[6])
      # up
      r2d.vertex(pt[8])
      r2d.vertex(pt[0])
      r2d.vertex(pt[3])
      r2d.vertex(pt[9])
      r2d.vertex(pt[8])
      r2d.vertex(pt[3])
      # left 
      r2d.vertex(pt[10])
      r2d.vertex(pt[11])
      r2d.vertex(pt[1])
      r2d.vertex(pt[0])
      r2d.vertex(pt[10])
      r2d.vertex(pt[1])
 
    let angleStep = 90f / segments.float
    let centers = [vec(ix,iy),vec(ix2,iy),vec(ix2,iy2),vec(ix,iy2)]
    let angles  = [180.0,90.0,0,270]
    #[
                  v1 
                    +
                  / \ 
                  /   \
                +-----+-----
                v2   |c
    ]#
    for indexCorner in 0..<4:
      let a = angles[indexCorner]
      let c = centers[indexCorner]
      for index in 0..<segments:
        let angle1 = a + angleStep * index.float
        let angle2 = angle1 + angleStep
        let v1 = radius * vec(sin(DEG2RAD * angle1), cos(DEG2RAD * angle1))
        let v2 = radius * vec(sin(DEG2RAD * angle2), cos(DEG2RAD * angle2))
        r2d.vertex(c.x + v1.x, c.y + v1.y, z)
        r2d.vertex(c.x + v2.x, c.y + v2.y, z)
        r2d.vertex(c.x, c.y, z)


proc rectRound*(api: P2DrawAPI, x,y,z: f32, w,h: f32, cx,cy: f32, angle: f32, roundness: f32, color: Color = cwhite) =
  const indices = 0
  const segments = 8
  const vertices = 30 + 4 * segments * 3
  let x   = x - cx * w
  let y   = y - cy * h
  let x2  = x + w
  let y2  = y + h
  # positions that forms inner centers of the rect
  let radius = if w > h: roundness * h * 0.5 else: roundness * w * 0.5
  let ix: f32 = x + radius
  let iy: f32 = y + radius
  let iw: f32 = w - radius * 2 
  let ih: f32 = h - radius * 2
  let ix2: f32 = ix + iw
  let iy2: f32 = iy + ih
  let angle  = m_math.degToRad(angle)
  let cos    = m_math.cos(angle)
  let sin    = m_math.sin(angle)
  let ox: f32 = x+cx*w
  let oy: f32 = y+cy*h
  let pt = [
    vecr(ix ,iy2,z,ox,oy,cos,sin),
    vecr(ix ,iy ,z,ox,oy,cos,sin),
    vecr(ix2,iy ,z,ox,oy,cos,sin),
    vecr(ix2,iy2,z,ox,oy,cos,sin),
    vecr(ix ,y  ,z,ox,oy,cos,sin),
    vecr(ix2,y  ,z,ox,oy,cos,sin),
    vecr(x2 ,iy ,z,ox,oy,cos,sin),
    vecr(x2 ,iy2,z,ox,oy,cos,sin),
    vecr(ix ,y2 ,z,ox,oy,cos,sin),
    vecr(ix2,y2 ,z,ox,oy,cos,sin),
    vecr(x  ,iy2,z,ox,oy,cos,sin),
    vecr(x  ,iy ,z,ox,oy,cos,sin),
  ]
  block body:
    r2d.draw(render2D.renderer, indices, vertices, R2D_GEOMETRY):
      r2d.color(color)
      r2d.texture(render2D.texWhiteId)
      # center
      r2d.vertex(pt[0])
      r2d.vertex(pt[1])
      r2d.vertex(pt[2])
      r2d.vertex(pt[3])
      r2d.vertex(pt[0])
      r2d.vertex(pt[2])
      # down
      r2d.vertex(pt[1])
      r2d.vertex(pt[4])
      r2d.vertex(pt[5])
      r2d.vertex(pt[2])
      r2d.vertex(pt[1])
      r2d.vertex(pt[5])
      # # right
      r2d.vertex(pt[3])
      r2d.vertex(pt[2])
      r2d.vertex(pt[6])
      r2d.vertex(pt[7])
      r2d.vertex(pt[3])
      r2d.vertex(pt[6])
      # up
      r2d.vertex(pt[8])
      r2d.vertex(pt[0])
      r2d.vertex(pt[3])
      r2d.vertex(pt[9])
      r2d.vertex(pt[8])
      r2d.vertex(pt[3])
      # left 
      r2d.vertex(pt[10])
      r2d.vertex(pt[11])
      r2d.vertex(pt[1])
      r2d.vertex(pt[0])
      r2d.vertex(pt[10])
      r2d.vertex(pt[1])
 
    let angleStep = 90f / segments.float
    let centers = [vec(ix,iy),vec(ix2,iy),vec(ix2,iy2),vec(ix,iy2)]
    let angles  = [180.0,90.0,0,270]
    #[
                  v1 
                    +
                  / \ 
                  /   \
                +-----+-----
                v2   |c
    ]#
    for indexCorner in 0..<4:
      let a = angles[indexCorner]
      let c = centers[indexCorner]
      for index in 0..<segments:
        let angle1 = a + angleStep * index.float
        let angle2 = angle1 + angleStep
        let v1 = radius * vec(sin(DEG2RAD * angle1), cos(DEG2RAD * angle1))
        let v2 = radius * vec(sin(DEG2RAD * angle2), cos(DEG2RAD * angle2))
        r2d.vertexr(c.x + v1.x, c.y + v1.y, z, ox, oy, cos, sin)
        r2d.vertexr(c.x + v2.x, c.y + v2.y, z, ox, oy, cos, sin)
        r2d.vertexr(c.x, c.y, z, ox, oy, cos, sin)


proc rectRoundLine*(api: P2DrawAPI, x,y,z: f32; w,h: f32, thickness: f32, roundness: f32, color: Color = cwhite) =
  #[
  Centers: p16-p19
  |        P5 ================== P4
  |      // P13              P12 \\
  |     //                        \\
  | P6 // P14                  P11 \\ P3
  |   ||   *P19             P18*    ||
  |   ||                            ||
  |   || P15                   P10  ||
  | P7 \\  *P16             P17*   // P2
  |     \\                        //
  |      \\ P8               P9 //
  |       P0 ================== P1 
  ]#
  const indices  = 0
  const segments = 8
  const vertices = 24 + 4 * segments * 6
  let cornerRadius = if w > h: h * roundness * 0.5 else: w * roundness * 0.5
  let inRadius     = cornerRadius
  let outRadius    = cornerRadius + thickness
  let pt =
    [
      vec(x+inRadius,y-thickness),
      vec(x+w-inRadius,y-thickness),
      vec(x+w+thickness,y+inRadius),

      vec(x+w+thickness,y+h-inRadius),
      vec(x+w-inRadius,y+h+thickness),

      vec(x+inRadius,y+h+thickness),
      vec(x-thickness,y+h-inRadius),
      vec(x-thickness,y+inRadius),
      
      vec(x+inRadius,y),
      vec(x+w-inRadius,y),

      vec(x+w,y+inRadius),
      vec(x+w,y+h-inRadius),

      vec(x+w-inRadius,y+h),
      vec(x+inRadius,y+h),

      vec(x,y+h-inRadius),
      vec(x,y+inRadius)
    ]
  let angleStep = 90f / segments.float
  let angles  = [180.0,90.0,0,270]
  let centers = [vec(x+inRadius,y+inRadius),vec(x+w-inRadius,y+inRadius),vec(x+w-inRadius,y+h-inRadius),vec(x+inRadius,y+h-inRadius)]
  r2d.draw(render2D.renderer, indices, vertices, R2D_GEOMETRY):
    r2d.color(color)
    for indexCorner in 0..<4:
      var a = angles[indexCorner]
      var c = centers[indexCorner]
      for index in 0..<segments:
        r2d.vertex(c.x + sin(DEG2RAD*a) * inRadius,                         c.y + cos(DEG2RAD*a)*inRadius, 0)
        r2d.vertex(c.x + sin(DEG2RAD*(a+angleStep)) * inRadius, c.y + cos(DEG2RAD*(a+angleStep))*inRadius, 0)
        r2d.vertex(c.x + sin(DEG2RAD*a) * outRadius,                       c.y + cos(DEG2RAD*a)*outRadius, 0)
        r2d.vertex(c.x + sin(DEG2RAD*(a+angleStep)) * inRadius,    c.y + cos(DEG2RAD*(a+angleStep))*inRadius, 0)
        r2d.vertex(c.x + sin(DEG2RAD*(a+angleStep)) * outRadius,  c.y + cos(DEG2RAD*(a+angleStep))*outRadius, 0)
        r2d.vertex(c.x + sin(DEG2RAD*a) * outRadius,                          c.y + cos(DEG2RAD*a)*outRadius, 0)
        a += angleStep
    # Bottom Left Right
    r2d.vertex(pt[0])
    r2d.vertex(pt[1])
    r2d.vertex(pt[8])
    r2d.vertex(pt[9])
    r2d.vertex(pt[8])
    r2d.vertex(pt[1])
    # Right Down Up
    r2d.vertex(pt[2])
    r2d.vertex(pt[3])
    r2d.vertex(pt[10])
    r2d.vertex(pt[11])
    r2d.vertex(pt[10])
    r2d.vertex(pt[3])
    # Up Left Right
    r2d.vertex(pt[4])
    r2d.vertex(pt[5])
    r2d.vertex(pt[12])
    r2d.vertex(pt[13])
    r2d.vertex(pt[12])
    r2d.vertex(pt[5])
    # Left Up Down
    r2d.vertex(pt[6])
    r2d.vertex(pt[7])
    r2d.vertex(pt[14])
    r2d.vertex(pt[15])
    r2d.vertex(pt[14])
    r2d.vertex(pt[7])


proc rectRoundLine*(api: P2DrawAPI, x,y,z: f32; w,h: f32,  cx,cy: f32, angle: f32, thickness: f32, roundness: f32, color: Color = cwhite) =
  #[
  Centers: p16-p19
  |        P5 ================== P4
  |      // P13              P12 \\
  |     //                        \\
  | P6 // P14                  P11 \\ P3
  |   ||   *P19             P18*    ||
  |   ||                            ||
  |   || P15                   P10  ||
  | P7 \\  *P16             P17*   // P2
  |     \\                        //
  |      \\ P8               P9 //
  |       P0 ================== P1 
  ]#
  const indices  = 0
  const segments = 8
  const vertices = 24 + 4 * segments * 6
  let x   = x - cx * w
  let y   = y - cy * h
  let angle  = m_math.degToRad(angle)
  let cos    = m_math.cos(angle)
  let sin    = m_math.sin(angle)
  let ox: f32 = x+cx*w
  let oy: f32 = y+cy*h
  let cornerRadius = if w > h: h * roundness * 0.5 else: w * roundness * 0.5
  let inRadius     = cornerRadius
  let outRadius    = cornerRadius + thickness
  let pt =
    [
      vecr(x+inRadius,y-thickness,z,ox,oy,cos,sin),
      vecr(x+w-inRadius,y-thickness,z,ox,oy,cos,sin),
      vecr(x+w+thickness,y+inRadius,z,ox,oy,cos,sin),

      vecr(x+w+thickness,y+h-inRadius,z,ox,oy,cos,sin),
      vecr(x+w-inRadius,y+h+thickness,z,ox,oy,cos,sin),

      vecr(x+inRadius,y+h+thickness,z,ox,oy,cos,sin),
      vecr(x-thickness,y+h-inRadius,z,ox,oy,cos,sin),
      vecr(x-thickness,y+inRadius,z,ox,oy,cos,sin),
      
      vecr(x+inRadius,y,z,ox,oy,cos,sin),
      vecr(x+w-inRadius,y,z,ox,oy,cos,sin),

      vecr(x+w,y+inRadius,z,ox,oy,cos,sin),
      vecr(x+w,y+h-inRadius,z,ox,oy,cos,sin),

      vecr(x+w-inRadius,y+h,z,ox,oy,cos,sin),
      vecr(x+inRadius,y+h,z,ox,oy,cos,sin),

      vecr(x,y+h-inRadius,z,ox,oy,cos,sin),
      vecr(x,y+inRadius,z,ox,oy,cos,sin)
    ]
  let angleStep = 90f / segments.float
  let angles  = [180.0,90.0,0,270]
  let centers = [vec(x+inRadius,y+inRadius),vec(x+w-inRadius,y+inRadius),vec(x+w-inRadius,y+h-inRadius),vec(x+inRadius,y+h-inRadius)]
  r2d.draw(render2D.renderer, indices, vertices, R2D_GEOMETRY):
    r2d.color(color)
    for indexCorner in 0..<4:
      var a = angles[indexCorner]
      var c = centers[indexCorner]
      for index in 0..<segments:
        r2d.vertexr(c.x + sin(DEG2RAD*a) * inRadius,              c.y + cos(DEG2RAD*a)*inRadius, z, ox, oy, cos, sin)
        r2d.vertexr(c.x + sin(DEG2RAD*(a+angleStep)) * inRadius,  c.y + cos(DEG2RAD*(a+angleStep))*inRadius, z, ox, oy, cos, sin)
        r2d.vertexr(c.x + sin(DEG2RAD*a) * outRadius,             c.y + cos(DEG2RAD*a)*outRadius, z, ox, oy, cos, sin)
        r2d.vertexr(c.x + sin(DEG2RAD*(a+angleStep)) * inRadius,  c.y + cos(DEG2RAD*(a+angleStep))*inRadius, z, ox, oy, cos, sin)
        r2d.vertexr(c.x + sin(DEG2RAD*(a+angleStep)) * outRadius, c.y + cos(DEG2RAD*(a+angleStep))*outRadius, z, ox, oy, cos, sin)
        r2d.vertexr(c.x + sin(DEG2RAD*a) * outRadius,             c.y + cos(DEG2RAD*a)*outRadius, z, ox, oy, cos, sin)
        a += angleStep
    # Bottom Left Right
    r2d.vertex(pt[0])
    r2d.vertex(pt[1])
    r2d.vertex(pt[8])
    r2d.vertex(pt[9])
    r2d.vertex(pt[8])
    r2d.vertex(pt[1])
    # Right Down Up
    r2d.vertex(pt[2])
    r2d.vertex(pt[3])
    r2d.vertex(pt[10])
    r2d.vertex(pt[11])
    r2d.vertex(pt[10])
    r2d.vertex(pt[3])
    # Up Left Right
    r2d.vertex(pt[4])
    r2d.vertex(pt[5])
    r2d.vertex(pt[12])
    r2d.vertex(pt[13])
    r2d.vertex(pt[12])
    r2d.vertex(pt[5])
    # Left Up Down
    r2d.vertex(pt[6])
    r2d.vertex(pt[7])
    r2d.vertex(pt[14])
    r2d.vertex(pt[15])
    r2d.vertex(pt[14])
    r2d.vertex(pt[7])


proc rectLine*(api: P2DrawAPI, x,y,z: f32; w,h: f32, cx,cy: f32, angle: f32, thickness: f32, color: Color = cwhite) =
  const indices = 0
  const vertices = 24
  let x   = x - cx * w
  let y   = y - cy * h
  let ox: f32 = x+cx*w
  let oy: f32 = y+cy*h
  let angle  = m_math.degToRad(angle)
  let cos    = m_math.cos(angle)
  let sin    = m_math.sin(angle)
  let pt =
      [
        vecr(x-thickness, y-thickness, z, ox, oy, cos, sin),
        vecr(x+w+thickness,y-thickness, z, ox, oy, cos, sin),
        vecr(x+w+thickness,y+h+thickness, z, ox, oy, cos, sin),
        vecr(x-thickness,y+h+thickness, z, ox, oy, cos, sin),
        vecr(x,y, z, ox, oy, cos, sin),
        vecr(x+w,y, z, ox, oy, cos, sin),
        vecr(x+w,y+h, z, ox, oy, cos, sin),
        vecr(x,y+h, z, ox, oy, cos, sin),
      ]
  r2d.draw(render2D.renderer, indices, vertices, R2D_GEOMETRY):
    r2d.color(color)
    r2d.texture(render2D.texWhiteId)
    r2d.vertex(pt[4])
    r2d.vertex(pt[0])
    r2d.vertex(pt[1])
    r2d.vertex(pt[5])
    r2d.vertex(pt[4])
    r2d.vertex(pt[1])

    r2d.vertex(pt[6])
    r2d.vertex(pt[5])
    r2d.vertex(pt[1])
    r2d.vertex(pt[2])
    r2d.vertex(pt[6])
    r2d.vertex(pt[1])

    r2d.vertex(pt[3])
    r2d.vertex(pt[7])
    r2d.vertex(pt[6])
    r2d.vertex(pt[2])
    r2d.vertex(pt[3])
    r2d.vertex(pt[6])

    r2d.vertex(pt[3])
    r2d.vertex(pt[0])
    r2d.vertex(pt[4])
    r2d.vertex(pt[7])
    r2d.vertex(pt[3])
    r2d.vertex(pt[4])


proc rectLine*(api: P2DrawAPI, x,y,z: f32; w,h: f32, thickness: f32, color: Color = cwhite) =
  const indices = 0
  const vertices = 24
  let pt =
      [
        vec(x-thickness, y-thickness, z),
        vec(x+w+thickness,y-thickness, z),
        vec(x+w+thickness,y+h+thickness, z),
        vec(x-thickness,y+h+thickness, z),
        vec(x,y, z),
        vec(x+w,y, z),
        vec(x+w,y+h, z),
        vec(x,y+h, z),
      ]
  r2d.draw(render2D.renderer, indices, vertices, R2D_GEOMETRY):
    r2d.color(color)
    # Bottom Left Right
    r2d.vertex(pt[4])
    r2d.vertex(pt[0])
    r2d.vertex(pt[1])
    r2d.vertex(pt[5])
    r2d.vertex(pt[4])
    r2d.vertex(pt[1])

    r2d.vertex(pt[6])
    r2d.vertex(pt[5])
    r2d.vertex(pt[1])
    r2d.vertex(pt[2])
    r2d.vertex(pt[6])
    r2d.vertex(pt[1])

    r2d.vertex(pt[3])
    r2d.vertex(pt[7])
    r2d.vertex(pt[6])
    r2d.vertex(pt[2])
    r2d.vertex(pt[3])
    r2d.vertex(pt[6])

    r2d.vertex(pt[3])
    r2d.vertex(pt[0])
    r2d.vertex(pt[4])
    r2d.vertex(pt[7])
    r2d.vertex(pt[3])
    r2d.vertex(pt[4])


proc rectRound*(api: P2DrawAPI, x,y: f32, w,h: f32, roundness: f32, color: Color = cwhite) =
  api.rectRound(x,y,0,w,h,roundness,color)


proc rectRound*(api: P2DrawAPI, x,y: f32, w,h: f32, cx,cy: f32, angle: f32, roundness: f32, color: Color = cwhite) =
  api.rectRound(x,y,0,w,h,cx,cy,angle,roundness,color)


proc rectRoundLine*(api: P2DrawAPI, x,y: f32; w,h: f32,  cx,cy: f32, angle: f32, thickness: f32, roundness: f32, color: Color = cwhite) =
  api.rectRoundLine(x,y,0,w,h,cx,cy,angle,thickness,roundness,color)


proc rectRoundLine*(api: P2DrawAPI, x,y: f32; w,h: f32, thickness: f32, roundness: f32, color: Color = cwhite) =
  api.rectRoundLine(x,y,0,w,h,thickness,roundness,color)


proc rectLine*(api: P2DrawAPI, x,y: f32; w,h: f32, cx,cy: f32, angle: f32, thickness: f32, color: Color = cwhite) =
  api.rectLine(x,y,0,w,h,cx,cy,angle,thickness,color)


proc rectLine*(api: P2DrawAPI, x,y: f32; w,h: f32, thickness: f32, color: Color = cwhite) =
  api.rectLine(x,y,0,w,h,thickness,color)


proc rect*(api: P2DrawAPI, x,y: f32; w,h: f32; color: Color = cwhite) =
  api.rect(x,y,0,w,h,color)


proc rect*(api: P2DrawAPI, x,y: f32; w,h: f32; cx,cy: f32, angle: f32, color: Color = cwhite) =
  api.rect(x,y,0,w,h,cx,cy,angle,color)



#------------------------------------------------------------------------------------------
# @api texture
#------------------------------------------------------------------------------------------
proc texture*(api: P2DrawAPI, texture: Texture2D, pos: Vec3, origin: Vec2 = vec2(0.5,0.5), scale: f32 = 1.0, color: Color = cWhite) =
  const indices = 6
  const vertices = 4
  let texture   = texture.get.addr
  let w         = texture.width.f32  * scale
  let h         = texture.height.f32 * scale
  let x         = pos.x - w * origin.x
  let y         = pos.y - h * origin.y
  r2d.draw(render2D.renderer, indices, vertices, R2D_SPRITE):
    r2d.texture(texture.id)
    r2d.color(color)
    r2d.vertex(x,  y,  pos.z,0f,0f) #A:0
    r2d.vertex(x+w,y,  pos.z,1f,0f) #B:1
    r2d.vertex(x+w,y+h,pos.z,1f,1f) #C:2
    r2d.vertex(x  ,y+h,pos.z,0f,1f) #D:3


proc texture*(api: P2DrawAPI, texture: Texture2D, pos: Vec3, origin: Vec2 = vec2(0.5,0.5), rotation: f32 = 0.0, scale: f32 = 1.0, color: Color = cWhite) =
  # origin is normalized
  # xx,yy: local position
  const indices = 6
  const vertices = 4
  let texture   = texture.get.addr
  if rotation == 0:
    let w         = texture.width.f32  * scale
    let h         = texture.height.f32 * scale
    let x         = pos.x - w * origin.x
    let y         = pos.y - h * origin.y
    r2d.draw(render2D.renderer, indices, vertices, R2D_SPRITE):
      r2d.texture(texture.id)
      r2d.color(color)
      r2d.vertex(x,  y,  pos.z, 0.0, 0.0) #A:0
      r2d.vertex(x+w,y,  pos.z, 1.0, 0.0) #B:1
      r2d.vertex(x+w,y+h,pos.z, 1.0, 1.0) #C:2
      r2d.vertex(x  ,y+h,pos.z, 0.0, 1.0) #D:3
  else:
    let sinRotation = sin(rotation*DEG2RAD)
    let cosRotation = cos(rotation*DEG2RAD)
    let w      = texture.width.f32  * scale
    let h      = texture.height.f32 * scale
    var xx     = -(w * origin.x)
    var yy     = -(h * origin.y)
    template vx(index: int): untyped {.dirty.} =
      when index == 0:
        pos.x + (xx*cosRotation)     + (yy*sinRotation)
      elif index == 1:
        pos.x + ((xx+w)*cosRotation) + (yy*sinRotation)
      elif index == 2:
        pos.x + ((xx+w)*cosRotation) + ((yy+h)*sinRotation)
      elif index == 3:
        pos.x + (xx*cosRotation)     + ((yy+h)*sinRotation)
      else:
        pxd.debug.fatal("Draw","ERROR")
        0.0
    template vy(index: int): untyped {.dirty.} =
      when index == 0:
        pos.y - (xx*sinRotation)     + (yy*cosRotation)
      elif index == 1:
        pos.y - ((xx+w)*sinRotation) + (yy*cosRotation)
      elif index == 2:
        pos.y - ((xx+w)*sinRotation) + ((yy+h)*cosRotation)
      elif index == 3:
        pos.y - (xx*sinRotation)     + ((yy+h)*cosRotation)
      else:
        pxd.debug.fatal("Draw","ERROR")
        0.0
    r2d.draw(render2D.renderer, indices, vertices, R2D_SPRITE):
      r2d.texture(texture.id)
      r2d.color(color)
      r2d.vertex(vx(0), vy(0), pos.z, 0.0, 0.0) #A:0
      r2d.vertex(vx(1), vy(1), pos.z, 1.0, 0.0) #B:1
      r2d.vertex(vx(2), vy(2), pos.z, 1.0, 1.0) #C:2
      r2d.vertex(vx(3), vy(3), pos.z, 0.0, 1.0) #D:3


#------------------------------------------------------------------------------------------
# @api sprite
#------------------------------------------------------------------------------------------
# Indices: DABCDB
# D----YT---C
# |    |    |
# XL---+---XR
# |    |    |
# A----YB---B
template inline_draw_sprite(renderer: Renderer2D) {.dirty.} =
  let w         = sprite.size.w * scale
  let h         = sprite.size.h * scale
  let x         = pos.x - w * sprite.origin.x
  let y         = pos.y - h * sprite.origin.y
  r2d.draw(renderer, indices, vertices, R2D_SPRITE):
    r2d.texture(sprite.texId)
    r2d.color(color)
    r2d.vertex(x,  y,  pos.z,sprite.texCoords[0]) #A:0
    r2d.vertex(x+w,y,  pos.z,sprite.texCoords[1]) #B:1
    r2d.vertex(x+w,y+h,pos.z,sprite.texCoords[2]) #C:2
    r2d.vertex(x  ,y+h,pos.z,sprite.texCoords[3]) #D:3


proc sprite*(api: P2DrawAPI, sprite: Sprite, pos: Vec3, scale: f32 = 1.0, color: Color = cWhite) {.inline.} =
  const indices = 6
  const vertices = 4
  let sprite    = sprite.get.addr
  inline_draw_sprite(render2D.renderer)


proc sprite*(api: P2DrawAPI, sprite: Sprite, pos: Vec3, rotation: f32 = 0.0, scale: f32 = 1.0, color: Color = cWhite) {.inline.} =
  # origin is normalized
  # xx,yy: local position
  const indices = 6
  const vertices = 4
  let sprite   = sprite.get.addr
  if rotation == 0:
    inline_draw_sprite(render2D.renderer)
  else:
    let sinRotation = sin(rotation*DEG2RAD)
    let cosRotation = cos(rotation*DEG2RAD)
    let w      = sprite.size.w * scale
    let h      = sprite.size.h * scale
    var xx     = -(w * sprite.origin.x)
    var yy     = -(h * sprite.origin.y)
    template vx(index: int): untyped {.dirty.} =
      when index == 0:
        pos.x + (xx*cosRotation)     + (yy*sinRotation)
      elif index == 1:
        pos.x + ((xx+w)*cosRotation) + (yy*sinRotation)
      elif index == 2:
        pos.x + ((xx+w)*cosRotation) + ((yy+h)*sinRotation)
      elif index == 3:
        pos.x + (xx*cosRotation)     + ((yy+h)*sinRotation)
      else:
        pxd.debug.fatal("Draw","ERROR")
        0.0
    template vy(index: int): untyped {.dirty.} =
      when index == 0:
        pos.y - (xx*sinRotation)     + (yy*cosRotation)
      elif index == 1:
        pos.y - ((xx+w)*sinRotation) + (yy*cosRotation)
      elif index == 2:
        pos.y - ((xx+w)*sinRotation) + ((yy+h)*cosRotation)
      elif index == 3:
        pos.y - (xx*sinRotation)     + ((yy+h)*cosRotation)
      else:
        pxd.debug.fatal("Draw","ERROR")
        0.0
    r2d.draw(render2D.renderer, indices, vertices, R2D_SPRITE):
      r2d.texture(sprite.texId)
      r2d.color(color)
      r2d.vertex(vx(0), vy(0), pos.z, sprite.texCoords[0]) #A:0
      r2d.vertex(vx(1), vy(1), pos.z, sprite.texCoords[1]) #B:1
      r2d.vertex(vx(2), vy(2), pos.z, sprite.texCoords[2]) #C:2
      r2d.vertex(vx(3), vy(3), pos.z, sprite.texCoords[3]) #D:3


#------------------------------------------------------------------------------------------
# @api font
#------------------------------------------------------------------------------------------
const SomeWhitespace = [" ", "\t", "\v", "\r", "\l", "\f"]


template cursorStep(): float {.dirty.} =
  (glyph.xadvance - fontPadding * 2) * textScale


template lineStep(): float {.dirty.} =
  (font.lineHeight.float + render2D.get.textLineSpacing) * textScale


template peekWordWidth(parseIndex: int): float {.dirty.} =
  var peekSize = 0.0
  block:
    var peekIndex = parseIndex
    while peekIndex < text.len:
      let rune    = text[peekIndex].Rune
      let runeUTF = rune.toUTF8()
      var glyph   = font.get.glyphs[int(rune)]
      case runeUTF:
        of SomeWhitespace:
          peekSize += cursorStep()
          break
        else:
          peekSize += cursorStep()
      inc peekIndex
  peekSize


template drawGlyph(glyph: var FontGlyph, pos: Vec3, scale: float = 1.0, color: Color = cWhite)  =
  const indices = 6
  const vertices = 4
  let sprite    = glyph.sprite.get.addr
  let w = sprite.size.w * scale
  let h = sprite.size.h * scale
  let x = pos.x + glyph.xoffset * scale
  var y = pos.y - glyph.yoffset * scale - h
  r2d.draw(render2D.renderer, indices, vertices, R2D_FONT):
    r2d.texture(sprite.texId)
    r2d.color(color)
    r2d.vertex(x,  y,  pos.z,sprite.texCoords[0]) #A:0
    r2d.vertex(x+w,y,  pos.z,sprite.texCoords[1]) #B:1
    r2d.vertex(x+w,y+h,pos.z,sprite.texCoords[2]) #C:2
    r2d.vertex(x  ,y+h,pos.z,sprite.texCoords[3]) #D:3


template textDraw() {.dirty.} =
  let rune    = text[parseIndex[]].Rune
  let runeUTF = rune.toUTF8()
  var glyph   = font.get.glyphs[int(rune)]
  case runeUTF:
    of "\n":
      cursor.y -= lineStep()
      cursor.x = pos.x
      inc parseIndex[]
      continue
    of " ":
      cursor.x += cursorStep()
      inc parseIndex[]
      continue
    else:
      drawGlyph(glyph, cursor, textScale, color)
      cursor.x += cursorStep()
  inc parseIndex[]


template textAlignBounds() {.dirty.} =
  var peekTextWidth = cursor.x + peekWordWidth(parseIndex[])
  if textBounds.x < peekTextWidth:
     cursor.y -= lineStep()
     cursor.x  = pos.x


proc text*(api: P2DrawAPI, text: string, pos: Vec3, textScale: f32 = 1.0, color: Color = cWhite) {.inline.} =
  render2D.renderer.useShader(render2d.get.fontShader):
    let parseIndex  = render2D.get.textParseIndex.addr
    let textBounds  = render2D.get.textBounds
    let font        = render2D.get.font
    let fontPadding = font.get.padding.float
    let fontSize    = font.get.size.float
    var cursor      = pos
    parseIndex[]    = 0
    if textBounds == vec2_default:
      # DRAW DEFAULT
      while parseIndex[] < text.len:
        textDraw()
    else: 
      # DRAW BOUNDEDED
      while parseIndex[] < text.len:
        textAlignBounds()
        textDraw()


proc text*(api: P2DrawAPI, text: string, x: f32, y: f32, z: f32, textScale: f32 = 1.0, color: Color = cWhite) {.inline.} =
  text(api, text, vec(x,y,z), textScale, color)


proc text*(api: P2DrawAPI, text: string, x: f32, y: f32, textScale: f32 = 1.0, color: Color = cWhite) {.inline.} =
  text(api, text, vec(x,y,0.0), textScale, color)


proc setFont*(api: P2DrawAPI, font: Font) =
  render2D.get.font = font


proc setTextLineSpacing*(api: P2DrawAPI, value: float) =
  render2D.get.textLineSpacing = value


proc resetFont*(api: P2DrawAPI) =
  render2D.get.font = render2D.get.fontDefault


template bounds*(api: P2DrawAPI, width: float, code: untyped) =
  render2D.get.textBounds = vec2(width, 0)
  code
  render2D.get.textBounds = vec2(0, 0)

































