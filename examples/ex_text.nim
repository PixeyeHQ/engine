import px_engine


pxd.run():
  let label      = "To anybody who's reading this, I pray that whatever is hurting you or whatever you are constantly stressing about gets better. May the dark thoughts, the overthinking, and the doubt exit your mind. May clarity replace confusion. May peace and calmness fill your life."
  var label_w    = float io.vars.get("app.window.w", int)[] - 300
  var label_size = 1.0
  let label_x    = 300.0
  let label_y    = float io.vars.get("app.window.h", int)[] - 100
  let input = pxd.inputs.get()

  let font_asset = pxd.res.load("./assets/fonts/iosevka_sdf.fnt")
  p2d.draw.setFont(font_asset.font)

  pxd.loop():
    if input.down(Key.Esc):
      pxd.closeApp()
    if input.down(Key.Q):
      label_w -= 50
    if input.down(Key.E):
      label_w += 50
    if input.down(Key.A):
      label_size -= 0.2
    if input.down(Key.D):
      label_size += 0.2
    pxd.render.draw():
      pxd.render.clear(0.3,0.3,0.4)
      pxd.render.mode(screen)
      p2d.draw.bounds(label_w):
        p2d.draw.text(label,label_x,label_y, label_size)