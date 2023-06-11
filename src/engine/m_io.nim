import std/os
import std/strformat
import engine/Px
import pxd/api
import pxd/m_vars
import pxd/m_pods


#------------------------------------------------------------------------------------------
# @api settings
#------------------------------------------------------------------------------------------
io.vars.put("app.developer", "PXD")
io.vars.put("app.title", "New Project")
io.vars.put("app.ups", 60)
io.vars.put("app.fps", 60)
io.vars.put("app.vsync", false)
io.vars.put("app.window.w", 1280)
io.vars.put("app.window.h", 720)


#------------------------------------------------------------------------------------------
# @api io
#------------------------------------------------------------------------------------------
type AppSettings = object
  window*: tuple[w: ptr int, h: ptr int]
  ups*: ptr int
  fps*: ptr int
  vsync*: ptr bool

type AppIO* = object
  settings*:    AppSettings
  screen*:      tuple[w: int, h: int, ratio: float]
  keepRunning*: bool
  ppu*:         int
  dataPath*:    string


var app_io = AppIO()
app_io.keepRunning = true
app_io.ppu         = 100
app_io.settings.window.w = io.vars.get("app.window.w", int)
app_io.settings.window.h = io.vars.get("app.window.h", int)
app_io.settings.fps      = io.vars.get("app.fps", int)
app_io.settings.ups      = io.vars.get("app.ups", int)
app_io.settings.vsync    = io.vars.get("app.vsync", bool)


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

{.pop.}


io.vars.put("runtime.initMessage", "")
io.vars.setFlags("runtime", VARS_DONT_SAVE)


template pt*(x: SomeNumber): float =
  ## Position relative to 0..1
  x * io.app.screen.ratio


template ppu*(x: SomeNumber): float =
  ## Pixel Per Unit
  x * io.app.ppu.f32


#------------------------------------------------------------------------------------------
# @api io paths
#------------------------------------------------------------------------------------------
proc path*(api: IoAPI, relativePath: string): string =
  case relativePath[0]:
    of '.':
      result = getAppDir() & substr(relativePath, 1)
    of '*':
      result = io.app.dataPath & substr(relativePath, 1)
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


#------------------------------------------------------------------------------------------
# @api events
#------------------------------------------------------------------------------------------
const EventEngine = EventId.Next(999_999)


template genEventAPI*(hook: PxdAPI, event: untyped, typeObjId: untyped, procId: untyped) {.dirty.} =
  var eventObj: typeObjId
  
  const event* {.inject.} = EventId.Next

  proc procId*(api: EventAPI): var typeObjId {.inject, inline.} =
    eventObj
  
  proc eventId*(self: var typeObjId): EventId {.inject, inline.} =
    event
template genEventAPI*(hook: PxdAPI, event: untyped) {.dirty.} =
  const event* {.inject.} = EventId.Next


type EventWindowResizeObj = object
  width*:  int
  height*: int


pxd.genEventAPI(EventWindowResize, EventWindowResizeObj, windowResize)


#------------------------------------------------------------------------------------------
# @api vars
#------------------------------------------------------------------------------------------
proc load*(api: VarsAPI, relativePath: string) =
  let path = io.path(relativePath)
  if fileExists(path):
    pxd.pods.fromPodFile(path, io.vars.source)
  else:
    pxd.pods.toPodFile(path, io.vars.source, PodSettings(style: PodStyle.Sparse))


proc save*(api: VarsAPI, relativePath: string) =
  let path =  io.path(relativePath)
  pxd.pods.toPodFile(path, io.vars.source, PodSettings(style: PodStyle.Sparse))


proc init*(api: IoAPI) =
  io.vars.load("./assets/engine.pods")
  block init_folders:
    let developer = io.vars.source["app.developer"].vstring
    let title     = io.vars.source["app.title"].vstring
    let path      = &"{getDataDir()}/{developer}/{title}"
    io.app.dataPath = path
    if not dirExists(path):
      createDir(path)