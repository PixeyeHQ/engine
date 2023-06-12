
#[
  Provide access to an object with different Id.
  Used in ECS where every component storage is registered for every registry (ECS World)
]#
import engine/pxd/m_utils_collections


type 
  ObjectContext*[T: object] = object
    data*:       seq[T]
    currentObj*: ptr T
  Context = ObjectContext


proc len*(self: var Context): int =
  self.data.len


proc setCurrent*(self: var Context, index: int) =
  self.currentObj = self.data[index].addr


proc initObjectContext*[T](_: typedesc[T], size: int): Context[T] =
  result.data = newSeq[T](size)
  result


proc `[]`*[T](self: var Context[T], index: SomeInteger): var T {.inline.} =
  self.data[index.int]


proc current*[T](self: var Context[T]): var T {.inline.} =
  self.currentObj[]


proc grow*[T](self: var Context[T], size: int): ptr T =
  self.data.grow(size)
  result = self.data[size].addr
