import std/tables


const POD_DONT_SAVE* = 1


type PodStyle* {.pure.} = enum 
  Compact,
  Sparse,
  Dense


type PodKind* = enum
  PInt,
  PBool,
  PFloat,
  PArray,
  PString,
  PObject,
 # PTable,
  PPointer


type PodSettings* = object
  style*: PodStyle


type PodErrorKind* = enum
  NoFile,
  NonConvertable,
  InvalidKey,
  InvalidNodeKey,
  InvalidStringEnding,
  InvalidTreeRootKey,
  InvalidNumber,
  UnknownValue


type PodError*  = object of ValueError


type PodWriter* = object of RootObj
  charIndex*: int
  buffer*:    string
  bufferLen*: int
  depth*:     int
  tokens*:    seq[string]
  ident*:     int
  objDepth*:  int


type PodReader* = object of RootObj
  charIndex*: int
  token*:     string
  source*:    ptr UncheckedArray[char]
  sourceLen*: int


type Pod* = object
  flag*: int
  case kind*: PodKind
    of PInt:
      vint*: int
    of PFloat:
      vfloat*: float
    of PBool:
      vbool*: bool
    of PString:
      vstring*: string
    of PArray:
      list*: seq[Pod]
    of PObject:
      isTable*: bool
      fields*:  OrderedTable[string,Pod]
    of PPointer:
      vpointer*: pointer


