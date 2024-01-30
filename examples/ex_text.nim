import ../src/px_engine

pxd.run():
  pxd.vars.put("runtime.ppu", 32.0)
  var assets = pxd.assets.getPack()
  var sw = pxd.vars.app_screen_w.f32
  var sh = pxd.vars.app_screen_h.f32
  let label      = "1234567890 To anybody who's reading this, I pray that whatever is hurting you or whatever you are constantly stressing about gets better. May the dark thoughts, the overthinking, and the doubt exit your mind. May clarity replace confusion. May peace and calmness fill your life."
  var label_w    = sw - 300
  var label_size = 15
  let label_x    = 300.0
  var label_y    = sh - 100
  let input = pxd.inputs.get()
  assets.load("./fonts/alterebro.fnt", true, Font)
  p2d.render.font = assets.get("./fonts/alterebro.fnt", Font)
  pxd.loop():
    label_w = sw - 300
    label_y = sh - 100
    if input.down(Key.Esc):
      pxd.closeApp()
    if input.down(Key.A):
      label_size -= 10
    if input.down(Key.D):
      label_size += 10
    pxd.draw():
      pxd.render.clear(0.3,0.3,0.4)
      pxd.render.target(screen)
      p2d.render.font.size = 32
      p2d.render.useShader(p2d.render.fontShader)
      p2d.render.uniform("outlineThickness", 0.5)
      p2d.draw.text(&"fps: {pxd.vars.metrics_fps}", 50, 50)
      p2d.draw.text(&"drawcalls: {pxd.vars.metrics_drawcalls}", 400, 50, 1, col(1,1,1,0.15))
      p2d.render.useShader(p2d.render.fontShader)
      p2d.render.uniform("outlineThickness", 0.0)
      p2d.render.font.size = label_size
      p2d.draw.text(label,label_x,label_y)
