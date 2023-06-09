import std/tables
export tables


type Storage*[T] = object
  availableIndices*: seq[int]
  items*: seq[T]
  map*:   Table[string,int]


type Element*[T] = object
  index*: int
  key*: string
  p*:   ptr T


type ElementId* = object
  index*: int
  key*: string
  p*:   pointer


proc `[]`*[T](self: var Storage[T], index: int): var T =
  self.items[index]


proc `[]`*[T](self: var Storage[T], key: string): var T =
  self.items[self.map[key]]


proc `[]`*[T](self: var Storage[T], element: T, key: string) =
  self.items[self.map[key]] = element



proc `[]`*[T](self: var Storage[T], id: ElementId): var T =
  if id.key.len > 0:
    return self[id.key]
  else:
    return self[id.index]


proc add*[T](self: var Storage[T], element: T): ElementId =
  var index = 0
  if self.availableIndices.len > 0:
    index = self.availableIndices.pop()
    self.items[index] = element
  else:
    self.items.add(element)
    index = self.items.high
  result.index = index


proc add*[T](self: var Storage[T], element: T, key: string): ElementId =
  result        = self.add(element)
  self.map[key] = result.index
  result.key    = key