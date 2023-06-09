#[
  Used in ImageObj asset instead of normal seq as it seems it's impossible to be sure that GC mem is freed when you need.
  [?] The case of loading heavy assets and clearing them on demand. 
  [?] But maybe there is something I don't know about how to do in Nim.
]#


import engine/pxd/api
import m_mem_d


proc initMem*(api: EngineAPI, len: int): Mem =
  result.data = cast[ptr UncheckedArray[uint8]](alloc0(len))
  result.len  = len


proc freeMem*(api: EngineAPI, mem: var Mem) =
  dealloc(mem.data)
  mem.len = 0


proc `[]`*(self: var Mem, index: int): var uint8 =
  self.data[index]