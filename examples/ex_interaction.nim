## This is an unfinished, unperformant and brute example of making objects react on mouse click
## The basic idea is to add interaction component that will handle the event based on some interaction area: circle, rect or 2d collider
## Also this example do some 2d object sorting by Y
import px_engine

# var camera: Camera
# var reg: Registry
# var spritesGroup: System
# var interactionGroup: System


# proc comparerDepthY(a,b: EId): int =
#   let ay = a.ctransform.position.y + a.csprite.height
#   let by = b.ctransform.position.y + b.csprite.height
#   if ay > by:
#     return 1
#   elif ay < by:
#     return -1
#   else:
#     return 0


# proc onEvent(ev: EventId) =
#   case ev:
#     of EventMouse:
#       var mousePosition = pxd.io.mouseWorldPosition

#       block check:
#         interactionGroup.sort(comparerDepthY)
#         for e in interactionGroup.entitiesInversed():
#           let transform   = e.ctransform
#           let interaction = e.cinteraction
#           interaction.rect.position = transform.position
#           if p2d.physics.inside(interaction.rect, mousePosition):
#               interaction.onClick()
#               break check
#     else:
#       discard


# pxd.run():
#   pxd.io.app.ppu = 32 # pixels per units
#   reg   = pxd.ecs.getRegistry()
  
#   spritesGroup     = pxd.ecs.builder.system(reg).with(CTransform,CSprite).build()
#   interactionGroup = pxd.ecs.builder.system(reg).with(CTransform,CSprite,CInteraction).build()

#   let atlas = pxd.res.get("./assets/images/atlases/player.json").spriteAtlas
#   let atlastree = pxd.res.get("./assets/images/atlases/tree.json").spriteAtlas
#   let spr     = atlas.sprite["player-0"]
#   let spr2    = atlastree.sprite["tree-1.png"]
#   let spr3    = atlastree.sprite["tree-2.png"]
#   let o       = p2d.create.sprite(reg, spr, vec(0,0,0), vec(0,0,0))
#   let o2      = p2d.create.sprite(reg, spr, vec(0,0,0), vec(0,0,0))
#   let o_tree1 = p2d.create.sprite(reg,spr3, vec(1,4,0), vec(0,0,0))
#   let o_tree2 = p2d.create.sprite(reg,spr2, vec(3,5,0), vec(0,0,0))
#   let o_tree3 = p2d.create.sprite(reg,spr2, vec(-4,-1,0), vec(0,0,0))
#   let o_tree4 = p2d.create.sprite(reg,spr3, vec(4,-3,0), vec(0,0,0))
#   o_tree1.csprite.height = 20.px
#   o_tree2.csprite.height = 20.px
#   o_tree3.csprite.height = 20.px
#   o_tree4.csprite.height = 20.px
#   block:
#     var cinteract = o.get CInteraction
#     let size = 12.px # by default we work in units, but for 2d it often good to do stuff in pixels.  .px calculates unit by dividing value on ppu.
#     cinteract.rect = p2d.physics.rect(0,0,size/2,size)
#     var clicked = false
#     cinteract.onClick = proc() =
#       clicked = not clicked
#       if clicked:
#         o.csprite.color = cgreen
#       else:
#         o.csprite.color = cwhite
#   block:
#     var cinteract = o2.get CInteraction
#     let size = 12.px
#     cinteract.rect = p2d.physics.rect(0,0,size/2,size)
#     var clicked = false
#     cinteract.onClick = proc() =
#       clicked = not clicked
#       if clicked:
#         o2.csprite.color = cred
#       else:
#         o2.csprite.color = cwhite
#   var cameraDef: CameraDef
#   block: # setup camera cfg
#     cameraDef.orthosize  = 5
#     cameraDef.planeNear  = 0.1
#     cameraDef.planeFar   = 100
#     cameraDef.zoom       = 1
#     cameraDef.projection = ProjectionKind.Orthographic
#   camera = pxd.create.camera(cameraDef)
#   let input  = pxd.inputs.get()
#   pxd.loop(onEvent):
#     block: # events
#       if input.down Key.Esc:
#         pxd.closeApp()
#       pxd.everyStep():
#         if input.get Key.A:
#           o.ctransform.position.x -= 1.px
#         if input.get Key.D:
#           o.ctransform.position.x += 1.px
#         if input.get Key.S:
#           o.ctransform.position.y -= 1.px
#         if input.get Key.W:
#           o.ctransform.position.y += 1.px
#         if input.get Key.Left:
#           camera.ctransform.position.x -= 12.px
#         if input.get Key.Right:
#           camera.ctransform.position.x += 12.px
#         if input.get Key.Down:
#           camera.ctransform.position.y -= 12.px
#         if input.get Key.Up:
#           camera.ctransform.position.y += 12.px
#     block: # debug
#       let title = &"Drawcalls: {$pxd.metrics.app.drawcalls} {$pxd.metrics.app}  ms: {dt*1000}"
#       pxd.platform.setWindowTitle(title)
#     pxd.draw():
#       pxd.render.clear(0.4,0.4,0.5)
#       block: # render game
#         pxd.render.mode(camera)
#         ## Engine is ecs driven.
#         # You can gather group of entities by components and perform actions on them, including sorting.
#         spritesGroup.sort(comparerDepthY)
#         for e in spritesGroup.entities():
#           let transform = e.ctransform
#           let sprite    = e.csprite
#           p2d.draw.sprite(sprite.data, transform.position, transform.rotation.z, sprite.data.scale, sprite.color)
#       block: # render ui
#         pxd.render.mode(screen)
#         p2d.draw.rect(10,10,300,10,cwhite)