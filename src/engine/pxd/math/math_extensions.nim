proc remap*(inputMin,inputMax: SomeNumber, outputMin,outputMax: SomeNumber, val: SomeNumber): SomeNumber =
  result = outputMin + (val - inputMin) * (outputMax - outputMin) / (inputMax - inputMin)

proc lerp*(x,y,a: SomeFloat): SomeFloat = x*(1-a)+y*a

func isNaN*(x: SomeFloat): bool {.inline.} =
  discard