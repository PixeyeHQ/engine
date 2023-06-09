type Mem* = object
  data*: ptr UncheckedArray[uint8]
  len*:  int