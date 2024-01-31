type
  f32* = float32
  f64* = float64
  i8* = int8
  i16* = int16
  i32* = int32
  i64* = int64
  u8* = uint8
  u32* = uint32
  u16* = uint16
  u64* = uint64
type
  API_Obj* = object
  Obj*      = ref object of RootObj
  MethodChain*[T] = object of RootObj
    state*: T
  ScreenMode* = enum screen
  
const
  ms008*:         float = 1.0/120
  ms016*:         float = 1.0/60
  ms032*:         float = 1.0/30
  msfluctuation*: float = 0.0002
  msgap*:         float = 10.0/59.0
let
  api_o* = API_Obj()


method drop*(self: Obj) {.base.} = discard


