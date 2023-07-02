type f32* = float32
type f64* = float64
type i8*  = int8
type i16* = int16
type i32* = int32
type i64* = int64
type u8*  = uint8
type u32* = uint32
type u16* = uint16
type u64* = uint64


const ms008*:         float = 1.0/120
const ms016*:         float = 1.0/60
const ms032*:         float = 1.0/30
const msfluctuation*: float = 0.0002
const msgap*:         float = 10.0/59.0


type SCREEN_MODE* = enum
  screen


type PeriodMode* = enum
  pm_seconds,
  pm_frames,
  pm_steps


template onCompile*(expression: untyped) =
  when compiles(expression):
    expression


template onCompile*(expression: untyped, code: untyped) =
  when compiles(expression):
    expression
    code


type Handle*  = u64
type Index*   = distinct u64
type EventId* = distinct u64

const HANDLE_NULL* = high(u64)


import std/macrocache
const nextIndex = CacheCounter"Pxd.Index"
const nextEventId = CacheCounter"Pxd.EventId"


proc Next*(api: typedesc[Index]): Index {.compileTime.} =
  result = Index(nextIndex.value)
  inc nextIndex
proc Next*(api: typedesc[Index], value: int): Index {.discardable, compileTime.} =
  inc nextIndex, value - nextIndex.value
  result = Index(nextIndex.value)
  inc nextIndex

proc Next*(api: typedesc[EventId]): EventId {.compileTime.} =
  result = EventId(nextEventId.value)
  inc nextEventId
proc Next*(api: typedesc[EventId], value: int): EventId {.discardable, compileTime.} =
  inc nextEventId, value - nextEventId.value
  result = EventId(nextEventId.value)
  inc nextEventId

const EVENT_ID_ENGINE* = 999_999