proc append*[T](self: var seq[T], index: int, item: T) =
  if self.len <= index:
    for i in self.len..index:
      self.add(nil)
  self[index] = item


proc appendPtr*[T](self: var seq[T]): ptr T {.discardable.} =
     self.add(T())
     self[self.high].addr


proc append*[T](self: var seq[T]): var T {.discardable.} =
     self.add(T())
     self[self.high]


proc append*[T](self: var seq[T], item: T): var T {.discardable.} =
     self.add(item)
     self[self.high]


template grow*[T](self: var seq[T], size: int, code: untyped) =
  when T is (object|seq|ptr|proc {.closure.}|Ordinal):
    while self.len <= size:
      self.setLen(self.len + int self.len / 2 + 2)
  elif T is ref object:
    while self.len <= size:
      self.add(T())
  code


proc grow*(self: var seq, size: int) =
  grow(self,size):
    discard


iterator pitems*[T](collection: var seq[T]): ptr T =
  var index = collection.low
  while index <= collection.high:
    yield collection[index].addr
    inc index


iterator pairs*[IX,T](a: seq[T]): tuple[key: IX, val: T] {.inline.} =
  ## Iterates over each item of `a`. Yields `(index, a[index])` pairs.
  var i = 0
  let L = len(a)
  while i < L:
    yield (i.IX, a[i])
    inc(i)


iterator mpairs*[IX,T](a: var seq[T]): tuple[key: IX, val: var T] {.inline.} =
  ## Iterates over each item of `a`. Yields `(index, a[index])` pairs.
  var i = 0
  let L = len(a)
  while i < L:
    yield (i.IX, a[i])
    inc(i)


proc findReversed*[T](collection: var seq[T], key: T): int =
    result = collection.high
    while (0 < result):
      if collection[result] == key:
        return result
      dec result
    result = -1