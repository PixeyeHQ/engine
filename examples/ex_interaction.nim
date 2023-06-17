## This is an unfinished, unperformant and brute example of making objects react on mouse click
## The basic idea is to add interaction component that will handle the event based on some interaction area: circle, rect or 2d collider
## Also this example do some 2d object sorting by Y
import std/algorithm
import px_engine
var camera: Camera
var sortedObjs = newseq[Ent]()

# brute Y sorting
proc sorty(a,b: Ent): int =
  var ay = a.ctransform.position.y
  var by = b.ctransform.position.y
  if ay > by:
    return -1
  elif ay < by:
    return 1
  else:
    return 0
proc sortyinv(a,b: Ent): int =
  var ay = a.ctransform.position.y
  var by = b.ctransform.position.y
  if ay > by:
    return 1
  elif ay < by:
    return -1
  else:
    return 0


proc sortObjs(sortFun: proc(a,b:Ent):int) =
  sortedObjs.setLen(0)
  for e, ctransform, csprite in pxd.ecs.components(Ent, CTransform, CSprite):
    sortedObjs.add(Ent(e))
  sort(sortedObjs,sortFun)


# todo: must be part of the px_engine in future
proc mouseWorldPosition(): Vec3 =
  let mx  = pxd.events.input.mouseX
  let my  = pxd.events.input.mouseY
  # normalize
  let nmx = mx / io.app.viewport.w.int
  let nmy = my / io.app.viewport.h.int
  # normalize device coords
  let ndcx = (nmx*2)-1
  let ndcy = 1 - (nmy*2)
  result.x = ndcx
  result.y = ndcy
  result.z = 0
  var r1 = mul(inverse(pxd.render.frame.uproj),pxd.render.frame.uview)
  result = mul(r1, vec(ndcx,ndcy,0,1))


proc onEvent(ev: EventId) =
  case ev:
    of EventWindowResize:
      print pxd.events.windowResize.height
    of EventMouse:
      var mpos = mouseWorldPosition()
      sortObjs(sortyinv)
      for e in sortedObjs.items:
        let ctransform   = e.ctransform
        let cinteraction = e.cinteraction
        # very brutal aabb check. 
        var x  = ctransform.position.x + cinteraction.rect.x
        var y  = ctransform.position.y + cinteraction.rect.y
        var xx = ctransform.position.x + cinteraction.rect.xx
        var yy = ctransform.position.y + cinteraction.rect.yy
        if mpos.x >= x and mpos.x <= xx and
           mpos.y >= y and mpos.y <= yy:
             cinteraction.onClick()
             break
    else:
      discard





pxd.run():
  io.app.ppu = 24 # pixels per units
  let reg   = pxd.ecs.getRegistry()
  var atlas = pxd.res.get("./assets/images/atlases/player.json").spriteAtlas
  var spr   = atlas.sprite["player-0"]
  var o     = pxd.create.sprite(reg, spr, vec(0,0,0), vec(0,0,0))
  var o2    = pxd.create.sprite(reg, spr, vec(1,0,0), vec(0,0,0))
  block:
    var cinteract = o.get CInteraction
    var size = 8.px # by default we work in units, but for 2d it often good to do stuff in pixels.  .px calculates unit by dividing value on ppu.
    cinteract.rect.x  = -size
    cinteract.rect.y  = -size
    cinteract.rect.xx = size
    cinteract.rect.yy = size
    var clicked = false
    cinteract.onClick = proc() =
      clicked = not clicked
      if clicked:
        o.csprite.color = cgreen
      else:
        o.csprite.color = cwhite
  block:
    var cinteract = o2.get CInteraction
    var size = 8.px
    cinteract.rect.x  = -size
    cinteract.rect.y  = -size
    cinteract.rect.xx = size
    cinteract.rect.yy = size
    var clicked = false
    cinteract.onClick = proc() =
      clicked = not clicked
      if clicked:
        o2.csprite.color = cred
      else:
        o2.csprite.color = cwhite
  var cameraCfg = ConfigCamera()
  block: # setup camera cfg
    cameraCfg.orthosize  = 5
    cameraCfg.planeNear  = 0.1
    cameraCfg.planeFar   = 1000
    cameraCfg.projection = ProjectionKind.Orthographic
  camera = pxd.create.camera(cameraCfg)
  let input  = pxd.inputs.get()
  var rotation = 0.0
  pxd.loop(onEvent):
    block: # events
      if input.down Key.Esc:
        pxd.closeApp()
      pxd.everyStep():
        if input.get Key.A:
          o.ctransform.position.x -= 1.px
        if input.get Key.D:
          o.ctransform.position.x += 1.px
        if input.get Key.S:
          o.ctransform.position.y -= 1.px
        if input.get Key.W:
          o.ctransform.position.y += 1.px
        if input.get Key.Left:
          camera.ctransform.position.x -= 12.px
        if input.get Key.Right:
          camera.ctransform.position.x += 12.px
        if input.get Key.Down:
          camera.ctransform.position.y -= 12.px
        if input.get Key.Up:
          camera.ctransform.position.y += 12.px
        if input.get Key.Q:
          o.ctransform.euler.z -= 10.px
        if input.get Key.E:
          o.ctransform.euler.z += 10.px
    block: # debug
      let title = &"Drawcalls: {$pxd.metrics.app.drawcalls} {$pxd.metrics.app}  ms: {dt*1000}"
      pxd.platform.setWindowTitle(title)
    pxd.render.draw():
      pxd.render.clear(0.4,0.4,0.5)
      block: # render game
        pxd.render.mode(camera)
        ## Engine is ecs driven.
        ## You can gather entities by components and perform actions on them.
        sortObjs(sorty)
        for e in sortedObjs.items:
          let ctransform = e.ctransform
          let csprite    = e.csprite
          p2d.draw.sprite(csprite.data, ctransform.position, ctransform.euler.z, csprite.data.scale, csprite.color)
      block: # render ui
        pxd.render.mode(screen)
        p2d.draw.rect(10,10,300,10,cwhite)
