import std/macrocache
import api
import m_platform
import m_math


type
  AppEventKind* {.pure.} = enum
    EWindowResize,
    EKeyUp,
    EKeyDown,
    EKey,
    EMouseMotion,
    EMouseDown,
    EMouseUp,
    EMouse
  EventObj* = ref object of Obj
  MouseStateObj = object
    x*,y*: int32
  InputKeyObj* = object
    key*: int
  MouseObj* = object
    key*: int
  AppEvent* = object
    case kind*: AppEventKind
      #of EWindowResize:
      #  windowResize*: WindowResizeObj
      of EKeyDown, EKey, EKeyUp:
        input*: InputKeyObj
      of EMouseDown, EMouseUp, EMouse:
        mouse*: InputKeyObj
      else:
        discard
proc `==`*(self: int, key: Key): bool = self == key.int

method execute*(ev: EventObj) {.base.} = discard


type
  EventId* = distinct uint64
const 
  nextEventId = CacheCounter"Pxd.EventId"
  EVENT_ID_ENGINE* = 999_999

proc Next*(api: typedesc[EventId]): EventId {.compileTime.} =
  result = EventId(nextEventId.value)
  inc nextEventId

proc Next*(api: typedesc[EventId], value: int): EventId {.discardable, compileTime.} =
  inc nextEventId, value - nextEventId.value
  result = EventId(nextEventId.value)
  inc nextEventId

template gen*(api: EventAPI, event: untyped, typeObjId: untyped, procId: untyped) =
  var eventObj: typeObjId
  var t {.used.} : typeObjId
  const event* {.inject.} = EventId.Next

  proc procId*(self: EventAPI): var typeObjId {.inject, inline.} =
    eventObj
  
  proc eventId*(self: var typeObjId): EventId {.inject, inline.} =
    event

template gen*(api: EventAPI, event: untyped) {.dirty.} =
  const event* {.inject.} = EventId.Next

const
  EventEngine = EventId.Next(EVENT_ID_ENGINE)



var mouseState: MouseStateObj
proc mouse*(api: VarsAPI): var MouseStateObj =
  mouseState