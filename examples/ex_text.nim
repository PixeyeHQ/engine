import px_engine
let io = pxd.io

pxd.run():
  var sw = io.app.screen.w.f32
  var sh = io.app.screen.h.f32
  let label      = "To anybody who's reading this, I pray that whatever is hurting you or whatever you are constantly stressing about gets better. May the dark thoughts, the overthinking, and the doubt exit your mind. May clarity replace confusion. May peace and calmness fill your life."
  var label_w    = sw - 300
  var label_size = 1.0
  let label_x    = 300.0
  var label_y    = sh - 100
  let input = pxd.inputs.get()

  let font_asset = pxd.res.load("./assets/fonts/iosevka_sdf.fnt")
  p2d.draw.setFont(font_asset.font)

  pxd.loop():
    sw = io.app.screen.w.f32
    sh = io.app.screen.h.f32
    label_w = sw - 300
    label_y = sh - 100
    if input.down(Key.Esc):
      pxd.closeApp()
    if input.down(Key.A):
      label_size -= 0.2
    if input.down(Key.D):
      label_size += 0.2
    pxd.draw():
      pxd.render.clear(0.3,0.3,0.4)
      pxd.render.mode(screen)
      p2d.draw.bounds(label_w):
        p2d.draw.text(label,label_x,label_y, label_size)