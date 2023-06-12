import std/strformat
import px_engine/pxd/api


type AppMetricsState* = object
  frames*:      int
  ticks*:       int
  drawcalls*:   int


type AppMetrics* = object
  fps*:         int = 60
  ups*:         int
  drawcalls*:   int


var metrics_o = AppMetrics()
var state_o   = AppMetricsState()


proc app*(api: MetricsAPI): var AppMetrics {.inline.} =
  metrics_o


proc state*(self: var AppMetrics): var AppMetricsState {.inline.} =
  state_o


proc `$`*(self: var AppMetrics): string =
  result = &("fps/ups: {self.fps}/{self.ups}")