import px_engine
# let io = pxd.io

# pxd.run():
#   pxd.vars.put("app.ups", 60)  # rewrite settings
#   pxd.vars.put("app.fps", 60) # rewrite settings
#   var atlas = pxd.res.get("./assets/images/atlases/player.json").spriteAtlas
#   var spr   = atlas.sprite["player-0"]
#   var cameraDef: CameraDef
#   block: # setup camera cfg
#     cameraDef.orthosize  = 24
#     cameraDef.planeNear  = 0.1
#     cameraDef.planeFar   = 1000
#     cameraDef.projection = ProjectionKind.Orthographic
#   let camera = pxd.create.camera(cameraDef)
#   let input  = pxd.inputs.get()
#   pxd.loop():
#     block: # events
#       if input.down Key.Esc:
#         pxd.closeApp()
#       pxd.everyStep():
#         if input.get Key.A:
#           camera.ctransform.position.x -= 1
#         if input.get Key.D:
#           camera.ctransform.position.x += 1
#         if input.get Key.S:
#           camera.ctransform.position.y -= 1
#         if input.get Key.W:
#           camera.ctransform.position.y += 1
#     block: # debug
#       let title = &"Drawcalls: {$pxd.metrics.app.drawcalls} {$pxd.metrics.app}  ms: {dt*1000}"
#       pxd.platform.setWindowTitle(title)
#     pxd.draw():
#       pxd.render.clear(0.4,0.4,0.5)
#       block: # render game
#         pxd.render.mode(camera)
#         p2d.draw.sprite(spr,vec3(0,0,0),24)
#       block: # render ui
#         pxd.render.mode(screen)
#         p2d.draw.rect(10,10,300,10,cwhite)