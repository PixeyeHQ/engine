import api

type
  TimerState = object
    scale*: float
    delta*: float
    deltaFixed*: float
    deltaUnscaled*: float
    timeElapsed*: float
    framesElapsed*: int
    stepLag*: float
  PeriodMode* = enum
    pm_seconds,
    pm_frames,
    pm_steps
var
  timer = TimerState(scale: 1.0)

proc state*(api: TimerAPI): var TimerState = timer


proc step*(api: TimerAPI): float {.inline.} =
  timer.delta


proc stepFixed*(api: TimerAPI): float {.inline.} =
  timer.deltaFixed


template every*(api: TimerAPI, value: float, mode: PeriodMode, code: untyped) =
  block:
    when mode == pm_seconds:
      var period {.global.} = timer.timeElapsed + value
      if timer.timeElapsed >= period:
        period = timer.timeElapsed + value
        code
    elif mode == pm_frames:
      var period {.global.} = timer.framesElapsed + value.int
      if timer.framesElapsed >= period:
        period = timer.framesElapsed + value.int
        code
    elif mode == pm_steps:
      var period {.global.} = timer.timeElapsed + value / 1000
      if timer.timeElapsed >= period:
        period = timer.timeElapsed + value / 1000
        code


template every*(api: TimerAPI, value: float, scale: float, mode: PeriodMode, code: untyped) =
  api.every(value / scale, mode, code)
