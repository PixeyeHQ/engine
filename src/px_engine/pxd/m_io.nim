import std/os
import px_engine/pxd/definition/api
import px_engine/pxd/m_vars
import px_engine/pxd/m_pods


#------------------------------------------------------------------------------------------
# @api settings
#------------------------------------------------------------------------------------------
pxd.vars.put("app.developer", "PXD")
pxd.vars.put("app.title", "New Project")
pxd.vars.put("app.ups", 60)
pxd.vars.put("app.fps", 60)
pxd.vars.put("app.ppu", 100)
pxd.vars.put("app.vsync", false)
pxd.vars.put("app.window.w", 1280)
pxd.vars.put("app.window.h", 720)


#------------------------------------------------------------------------------------------
# @api io
#------------------------------------------------------------------------------------------
type AppSettings = object
  window*: tuple[w: ptr int, h: ptr int]
  ups*: ptr int
  fps*: ptr int
  vsync*: ptr bool


type AppIO = object
  settings*:    AppSettings
  screen*:      tuple[w: int, h: int, ratio: float]
  viewport*:    tuple[w: float, h: float]
  keepRunning*: bool
  ppu*:         int
  dataPath*:    string


var app_io = AppIO()
app_io.keepRunning = true
app_io.ppu               = pxd.vars.get("app.ppu", int)[]
app_io.settings.window.w = pxd.vars.get("app.window.w", int)
app_io.settings.window.h = pxd.vars.get("app.window.h", int)
app_io.settings.fps      = pxd.vars.get("app.fps", int)
app_io.settings.ups      = pxd.vars.get("app.ups", int)
app_io.settings.vsync    = pxd.vars.get("app.vsync", bool)


{.push inline.}


proc app*(api: IoAPI): var AppIO =
  app_io


proc ups*(self: var AppIO): int =
  self.settings.ups[]


proc fps*(self: var AppIO): int =
  self.settings.fps[]


proc vsync*(self: var AppIO): bool =
  self.settings.vsync[]


proc setVsync*(self: var AppIO, arg: bool) =
  self.settings.vsync[] = arg


proc aspectRatio*(self: var AppIO): float =
  float pxd.io.app.screen.ratio


{.pop.}


template pt*(x: SomeNumber): float =
  ## Position relative to 0..1
  x * app_io.screen.ratio


template ppu*(x: SomeNumber): float =
  ## Pixel Per Unit
  x * app_io.ppu.f32


template px*(x: SomeNumber): float =
  ## Pixel Per Unit
  x / app_io.ppu.f32


#------------------------------------------------------------------------------------------
# @api io paths
#------------------------------------------------------------------------------------------
proc path*(api: IoAPI, relativePath: string): string =
  case relativePath[0]:
    of '.':
      result = getAppDir() & substr(relativePath, 1)
    of '*':
      result = app_io.dataPath & substr(relativePath, 1)
    else:
      result = "invalid path: " & relativePath


proc pathExtension*(api: IoAPI, path: string): string =
  let indexFrom = searchExtPos(path) + 1
  let indexTo   = path.len
  result = substr(path, indexFrom, indexTo)


proc pathWithoutExtension*(api: IoAPI, path: string): string = 
  let indexFrom = 0
  let indexTo   = searchExtPos(path) - 1
  result = substr(path, indexFrom, indexTo)


# proc load*(api: VarsAPI, relativePath: string) =
#   let path = pxd.io.path(relativePath)
#   if fileExists(path):
#     pxd.pods.fromPodFile(path, pxd.vars.source)
#   else:
#     pxd.pods.toPodFile(path, pxd.vars.source, PodSettings(style: PodStyle.Sparse))


# proc save*(api: VarsAPI, relativePath: string) =
#   let path =  pxd.io.path(relativePath)
#   pxd.pods.toPodFile(path, pxd.vars.source, PodSettings(style: PodStyle.Sparse))


# proc init*(api: IoAPI) =
#   pxd.vars.load("./assets/engine.pods")
#   block init_folders:
#     let developer = pxd.vars.source["app.developer"].vstring
#     let title     = pxd.vars.source["app.title"].vstring
#     let path      = &"{getDataDir()}/{developer}/{title}"
#     pxd.io.app.dataPath = path
#     if not dirExists(path):
#       createDir(path)
#   pxd.io.app.screen.w     = pxd.io.app.settings.window.w[]
#   pxd.io.app.screen.h     = pxd.io.app.settings.window.h[]
#   pxd.io.app.screen.ratio = float pxd.io.app.screen.w / pxd.io.app.screen.h