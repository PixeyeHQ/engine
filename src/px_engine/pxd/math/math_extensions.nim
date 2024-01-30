import std/math
import ../api
import math_d
import math_vector


proc tolerate*(api: MathAPI, x: float, tolerance: float): float {.inline.} =
  if x > 1.0 - tolerance:
    return 1.0
  elif x <= tolerance:
    return 0.0
  x


proc remap*(api: MathAPI, x, inMin, inMax, outMin, outMax: SomeNumber): SomeNumber {.inline.} =
  (x - inMin) / (inMax - inMin) * (outMax - outMin) + outMin

proc lerp*(api: MathAPI, x,y: SomeNumber; a: float): SomeFloat = x.float*(1-a)+y.float*a

proc lerp*(api: MathAPI, a,b: Vec3, t: float): Vec3 =
  vec3(a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t,a.z+(b.z-a.z)*t)


proc lerp*(api: MathAPI, a,b: Vec, t: float): Vec =
  vec(a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t,a.z+(b.z-a.z)*t,a.w+(b.w-a.w)*t)


func isNaN*(api: MathAPI, x: SomeFloat): bool {.inline.} =
  discard


proc fastSqrt*(api: MathAPI, x: float): float =
  ## Babylonian method
  var guess: float = x / 2.0
  for i in 0..2:
    guess = (guess + x / guess) / 2.0
  return guess


proc smallestPowerOf2*(api: MathAPI, n: int): int =
  return 2 ^ int(ceil(log2(float(n))))


proc sign*(api: MathAPI, n: SomeNumber): SomeNumber {.inline.} =
  if n < 0:
    result = -1
  else:
    result = 1