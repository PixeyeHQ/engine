import px_engine/pxd/definition/api
import px_engine/pxd/data/data_mem_d


type 
  ImageObject* = object
    width*:      i32
    height*:     i32
    components*: int
    mem*:        Mem

  Image* = distinct Handle