## This is an unfinished, unperformant and brute example of making objects react on mouse click
## The basic idea is to add interaction component that will handle the event based on some interaction area: circle, rect or 2d collider
## Also this example do some 2d object sorting by Y
import px_engine


var camera: Camera
var reg: Registry
var spritesGroup: System
var interactionGroup: System


proc comparerDepthY(a,b: EId): int =
  var ay = a.ctransform.position.y + a.csprite.height
  var by = b.ctransform.position.y + b.csprite.height
  if ay >= by:
    return 1
  elif ay < by:
    return -1


proc onEvent(ev: EventId) =
  case ev:
    of EventMouse:
      var mpos = io.mousePosition
      block check:
        interactionGroup.sort(comparerDepthY)
        for e in interactionGroup.entitiesInversed():
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
              break check

    else:
      discard


pxd.run():
  io.app.ppu = 24 # pixels per units
  reg   = pxd.ecs.getRegistry()
  
  spritesGroup     = pxd.ecs.builder.system(reg).with(CTransform,CSprite).build()
  interactionGroup = pxd.ecs.builder.system(reg).with(CTransform,CSprite,CInteraction).build()

  let atlas = pxd.res.get("./assets/images/atlases/player.json").spriteAtlas
  let atlastree = pxd.res.get("./assets/images/atlases/tree.json").spriteAtlas
  let spr    = atlas.sprite["player-0"]
  let spr2   = atlastree.sprite["tree-1.png"]
  let spr3   = atlastree.sprite["tree-2.png"]
  let o     = pxd.create.sprite(reg, spr, vec(0,0,0), vec(0,0,0))
  let o2    = pxd.create.sprite(reg, spr, vec(1,0,0), vec(0,0,0))
  let o_tree1 = pxd.create.sprite(reg,spr3, vec(-3,0,0), vec(0,0,0))
  let o_tree2 = pxd.create.sprite(reg,spr2, vec(-4,-3,0), vec(0,0,0))
  let o_tree3 = pxd.create.sprite(reg,spr2, vec(2,-5,0), vec(0,0,0))
  let o_tree4 = pxd.create.sprite(reg,spr3, vec(3,2,0), vec(0,0,0))
  o_tree1.csprite.height = 20.px
  o_tree2.csprite.height = 20.px
  o_tree3.csprite.height = 20.px
  o_tree4.csprite.height = 20.px
  block:
    var cinteract = o.get CInteraction
    let size = 8.px # by default we work in units, but for 2d it often good to do stuff in pixels.  .px calculates unit by dividing value on ppu.
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
    let size = 8.px
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
    cameraCfg.planeFar   = 100
    cameraCfg.projection = ProjectionKind.Orthographic
  camera = pxd.create.camera(cameraCfg)
  let input  = pxd.inputs.get()
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
    block: # debug
      let title = &"Drawcalls: {$pxd.metrics.app.drawcalls} {$pxd.metrics.app}  ms: {dt*1000}"
      pxd.platform.setWindowTitle(title)
    pxd.render.draw():
      pxd.render.clear(0.4,0.4,0.5)
      block: # render game
        pxd.render.mode(camera)
        ## Engine is ecs driven.
        ## You can gather group of entities by components and perform actions on them, including sorting.
        spritesGroup.sort(comparerDepthY)
        for e in spritesGroup.entities():
          let ctransform = e.ctransform
          let csprite    = e.csprite
          p2d.draw.sprite(csprite.data, ctransform.position, ctransform.euler.z, csprite.data.scale, csprite.color)
      block: # render ui
        pxd.render.mode(screen)
        p2d.draw.rect(10,10,300,10,cwhite)