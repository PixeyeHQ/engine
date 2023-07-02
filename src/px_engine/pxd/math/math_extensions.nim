proc remap*(x, inMin, inMax, outMin, outMax: SomeNumber): SomeNumber {.inline.} =
  (x - inMin) / (inMax - inMin) * (outMax - outMin) + outMin

proc lerp*(x,y,a: SomeFloat): SomeFloat = x*(1-a)+y*a

func isNaN*(x: SomeFloat): bool {.inline.} =
  discard

proc fastSqrt*(x: float): float =
  ## Babylonian method
  var guess: float = x / 2.0
  for i in 0..2:
    guess = (guess + x / guess) / 2.0
  return guess