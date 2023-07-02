#[
  Incomplete module. Currently physics can handle overlaps of  circle, aabb, convex polygon and check if point is inside of a shape.
]#
import px_engine


pxd.run():
  pxd.io.app.ppu = 32
  var cameraDef: CameraDef
  block: # setup camera
    cameraDef.orthosize  = 10
    cameraDef.planeNear  = 0.1
    cameraDef.planeFar   = 100
    cameraDef.projection =  ProjectionKind.Orthographic
    cameraDef.zoom       = 1.0
  let camera = pxd.create.camera(cameraDef)
  let input  = pxd.inputs.get()

  var poly1 = p2d.physics.polygon(-7.0,0).asRect(1,3)
  var poly2 = p2d.physics.polygon(-7,2).asRect(3,1)
  var poly3 = p2d.physics.polygon(0,0).asRectRound(2,5,1)
  var circ1 = p2d.physics.circle(5,5,2)
  var circ2 = p2d.physics.circle(3,5,1)
  pxd.loop():
    poly1.update()
    poly2.update()
    poly3.update()
    poly1.rotation -= 1.0
    poly2.rotation += 1.0
    poly3.rotation += 0.5
    let mousePosition = pxd.io.mouseWorldPosition
    let mouseInsidePoly3 = p2d.physics.inside(poly3, mousePosition)
    let mouseInsidePoly1 = p2d.physics.inside(poly1, mousePosition)
    let mouseInsideCirc1 = p2d.physics.inside(circ1, mousePosition)
    let polyOverlap      = p2d.physics.overlap(poly1,poly2)
    let circleOverlap    = p2d.physics.overlap(circ1,circ2)
    pxd.draw():
      let lineWidth = 2.px
      pxd.render.clear(0.4,0.4,0.5)
      pxd.render.mode(camera)
      if mouseInsidePoly3:
        p2d.draw.rectRoundLine(poly3.position.x, poly3.position.y, 2, 5, 0.5, 0.5, poly3.rotation, lineWidth, 1, cblue)
        p2d.draw.circle(mousePosition.x,mousePosition.y,5.px,cred)
      else:
        p2d.draw.rectRoundLine(poly3.position.x, poly3.position.y, 2, 5, 0.5, 0.5, poly3.rotation, lineWidth, 1, cwhite)
      if polyOverlap:
        p2d.draw.rectLine(poly1.position.x, poly1.position.y, 1, 3, 0.5, 0.5, poly1.rotation, lineWidth, cblue)
        p2d.draw.rectLine(poly2.position.x, poly2.position.y, 3, 1, 0.5, 0.5, poly2.rotation, lineWidth, cblue)
      else:
        p2d.draw.rectLine(poly1.position.x, poly1.position.y, 1, 3, 0.5, 0.5, poly1.rotation, lineWidth, cwhite)
        p2d.draw.rectLine(poly2.position.x, poly2.position.y, 3, 1, 0.5, 0.5, poly2.rotation, lineWidth, cwhite)
      if circleOverlap:
        p2d.draw.circleLine(circ1.position.x,circ1.position.y,2,lineWidth,cblue)
        p2d.draw.circleLine(circ2.position.x,circ2.position.y,1,lineWidth,cblue)
      else:
        p2d.draw.circleLine(circ1.position.x,circ1.position.y,2,lineWidth,cwhite)
        p2d.draw.circleLine(circ2.position.x,circ2.position.y,1,lineWidth,cwhite)
      if mouseInsidePoly1:
        p2d.draw.rectLine(poly1.position.x, poly1.position.y, 1, 3, 0.5, 0.5, poly1.rotation, lineWidth*2, cred)
      if mouseInsideCirc1:
        p2d.draw.circleLine(circ1.position.x,circ1.position.y,2,lineWidth*2,cred)