import px_engine/pxd/definition/api


type TimeState = object
  scale*: float
  delta*: float
  deltaUnscaled*: float
  timeElapsed*: float
  ticksElapsed*: int
  framesElapsed*: int
  stepLag*: float


var timeState = TimeState(); timeState.scale = 1.0


proc state*(api: TimeAPI): var TimeState {.inline.} =
  timeState


proc delta*(api: TimeAPI): float {.inline.} =
  timeState.delta


template every*(api: TimeAPI, value: float, mode: PeriodMode, code: untyped) =
  block:
    when mode == pm_seconds:
      var period {.global.} = timeState.timeElapsed + value
      if timeState.timeElapsed >= period:
        period = timeState.timeElapsed + value
        code
    elif mode == pm_frames:
      var period {.global.} = timeState.framesElapsed + value.int
      if timeState.framesElapsed >= period:
        period = timeState.framesElapsed + value.int
        code
    elif mode == pm_steps:
      var period {.global.} = timeState.ticksElapsed + value.int
      if timeState.ticksElapsed >= period:
        period = timeState.ticksElapsed + value.int
        code


template every*(api: TimeAPI, value: float, scale: float, mode: PeriodMode, code: untyped) =
  api.every(value / scale, mode, code)


