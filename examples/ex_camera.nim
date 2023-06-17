import px_engine


pxd.run():
  io.vars.put("app.ups", 60)  # rewrite settings
  io.vars.put("app.fps", 60) # rewrite settings
  var atlas = pxd.res.get("./assets/images/atlases/player.json").spriteAtlas
  var spr   = atlas.sprite["player-0"]
  var cameraCfg = ConfigCamera()
  block: # setup camera cfg
    cameraCfg.orthosize  = 24
    cameraCfg.planeNear  = 0.1
    cameraCfg.planeFar   = 1000
    cameraCfg.projection = ProjectionKind.Orthographic
  let camera = pxd.create.camera(cameraCfg)
  let input  = pxd.inputs.get()
  pxd.loop():
    block: # events
      if input.down Key.Esc:
        pxd.closeApp()
      pxd.everyStep():
        if input.get Key.A:
          camera.ctransform.position.x -= 1
        if input.get Key.D:
          camera.ctransform.position.x += 1
        if input.get Key.S:
          camera.ctransform.position.y -= 1
        if input.get Key.W:
          camera.ctransform.position.y += 1
    block: # debug
      let title = &"Drawcalls: {$pxd.metrics.app.drawcalls} {$pxd.metrics.app}  ms: {dt*1000}"
      pxd.platform.setWindowTitle(title)
    pxd.render.draw():
      pxd.render.clear(0.4,0.4,0.5)
      block: # render game
        pxd.render.mode(camera)
        p2d.draw.sprite(spr,vec3(0,0,0),24)
      block: # render ui
        pxd.render.mode(screen)
        p2d.draw.rect(10,10,300,10,cwhite)