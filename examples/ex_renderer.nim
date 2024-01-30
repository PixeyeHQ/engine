import px_engine
# import std/random; randomize()
# const SPRITES_AMOUNT = 30000
# const SPRITE_SIZE    = 200
# let io = pxd.io


# pxd.run():
#   var screen_w = float io.app.screen.w
#   var screen_h = float io.app.screen.h
#   var frame = 0
#   #todo: make nice animation abstraction.
#   var atlas = pxd.res.get("./assets/images/atlases/player.json").spriteAtlas
  
#   var sprs = newSeq[Sprite]()
#   sprs.add(atlas.sprite["player-0"])
#   sprs.add(atlas.sprite["player-1"])
#   sprs.add(atlas.sprite["player-2"])
#   sprs.add(atlas.sprite["player-3"])
#   sprs.add(atlas.sprite["player-4"])
#   sprs.add(atlas.sprite["player-5"])

#   p2d.draw.setFont(pxd.res.get("./assets/fonts/iosevka_sdf.fnt").font)

#   var pawns_positions = newseq[Vec3]()
#   var pawns_frame     = newseq[int]()
#   for i in 0..SPRITES_AMOUNT:
#     pawns_positions.add(vec(rand(0..screen_w.int).float,rand(0..screen_h.int).float))
#     pawns_frame.add(rand(0..6))
  
#   let input = pxd.inputs.get()
#   pxd.loop():
#     screen_w = float io.app.screen.w
#     screen_h = float io.app.screen.h
#     pxd.time.every(1, pm_seconds):
#       inc frame
#       frame = frame mod 6
#     if input.down(Key.Esc):
#       pxd.closeApp()

#     pxd.draw():
#       pxd.render.clear(0.3, 0.3, 0.4)
#       pxd.render.mode(screen)

#       block sprite:
#         for i in 0..SPRITES_AMOUNT:
#           p2d.draw.sprite(sprs[((frame + pawns_frame[i]) mod 6)], pawns_positions[i], SPRITE_SIZE)

#       block metrics:
#         p2d.draw.rect(0,screen_h-175,275,175,rgba(0,0,0,0.6))
#         p2d.draw.text(&"sprites: {SPRITES_AMOUNT}", 25, screen_h - 25, 0.4, cwhite)
#         p2d.draw.text(&"drawcalls: {$pxd.metrics.app.drawcalls}", 25, screen_h - 70, 0.4, cwhite)
#         p2d.draw.text(&"{$pxd.metrics.app}", 25, screen_h - 115, 0.4, cwhite)
