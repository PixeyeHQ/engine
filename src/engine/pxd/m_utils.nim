type MethodChain*[T] = object of RootObj
  state*: T


proc numFields*[T](x: T): int =
  for _ in x.fields:
    inc result


proc numFields*[T](x: var T): int =
  for _ in x.fields:
    inc result


proc get*[T](x: var seq[T], index: int): T =
  if index >= x.len:
    x.setLen(index+1)
  return x[index]


proc getPtr*[T](x: var seq[T], index: int): ptr T =
  if index >= x.len:
    x.setLen(index+1)
  return x[index].addr


template `?`*[T](action: T): auto =
  if action == nil:
    return false
  action


template `?f`*[T](action: T): auto =
  if action == nil:
    return 0f
  action