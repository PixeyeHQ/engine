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
type v8*  = char


const ms008*:         float32 = 1/120
const ms016*:         float32 = 1/60
const ms032*:         float32 = 1/30
const msfluctuation*: float32 = 0.0002
const msgap*:         float32 = 15/60


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


type Handle*  = uint64
type Index*   = distinct uint64
type EventId* = distinct uint64

const HANDLE_NULL* = high(uint64)

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


