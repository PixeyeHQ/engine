import px_engine/pxd/definition/api

type Sound_Obj* = object
  data*:    pointer
  channel*: cint
type Sound* = distinct Handle

type Music_Obj* = object
  data*: pointer
type Music* = distinct Handle