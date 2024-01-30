proc incGet*(x: var SomeInteger): SomeInteger {.inline, discardable.} =
    ## Increment `x` and return the incremented value. Discardable.
    ## Same as ``++x`` pre-increment in C.
    system.inc x
    result = x

proc getInc*(x: var SomeInteger): SomeInteger {.inline, discardable.} =
    ## Increment `x` but return the value before the increment.
    ## Same as ``x++`` post-increment in C
    result = x
    system.inc x

proc getDec*(x: var SomeInteger): SomeInteger {.inline, discardable.} =
    ## Decrease `x` but return the value before the operation.
    ## Same as ``x--`` post-decrement in C
    result = x
    system.dec x

proc decGet*(x: var SomeInteger): SomeInteger {.inline, discardable.} =
    ## Decrease `x`  and return the value. Discardable.
    ## Same as ``--x`` pre-decrement in C
    system.dec x
    result = x

template `?`*[T](action: T): auto =
  if action == nil:
    return false
  action

template `?f`*[T](action: T): auto =
  if action == nil:
    return 0f
  action

template repeat*(amount: int, code: untyped) =
  for i in 0..<amount:
    code
