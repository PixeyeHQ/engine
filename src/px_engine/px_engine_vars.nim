import px_pods
import pxd/[api, m_vars]

pxd.vars.gen(app_title, "app.title", "New Game")
pxd.vars.gen(app_developer, "app.developer", "Pixeye Games")
pxd.vars.gen(app_window_w, "app.window.w", 1280)
pxd.vars.gen(app_window_h, "app.window.h", 720)
pxd.vars.gen(app_fps, "app.fps", 60)
pxd.vars.gen(app_ups, "app.ups", 60)
pxd.vars.gen(app_wantsQuit, "app.wantsQuit", false)
pxd.vars.gen(app_screen_w, "app.screen.w", 1280)
pxd.vars.gen(app_screen_h, "app.screen.h", 720)
pxd.vars.gen(app_vsync, "app.vsync", false)
pxd.vars.gen(runtime_screen_ratio, "runtime.screen.ratio", 0.0)
pxd.vars.gen(runtime_viewport_w, "runtime.viewport.w", 0.0)
pxd.vars.gen(runtime_viewport_h, "runtime.viewport.h", 0.0)
pxd.vars.gen(runtime_drawcalls, "runtime.drawcalls", 0)
pxd.vars.gen(metrics_fps, "metrics.fps", 0)
pxd.vars.gen(metrics_ups, "metrics.ups", 0)
pxd.vars.gen(metrics_drawcalls, "metrics.drawcalls", 0)

pxd.vars.put("app.screen.w", pxd.vars.app_window_w)
pxd.vars.put("app.screen.h", pxd.vars.app_window_h)
pxd.vars.put("runtime.initMessage", "")
pxd.vars.put("runtime.ppu", 32.0)
pxd.vars.put("runtime.screen.ratio", float pxd.vars.app_screen_w / pxd.vars.app_screen_h)

pxd.vars.setFlags("runtime", VARS_DONT_SAVE)
pxd.vars.setFlags("metrics", VARS_DONT_SAVE)