#------------------------------------------------------------------------------------------
# @api pod define
#------------------------------------------------------------------------------------------
import std/os
import std/sets
import std/tables
import std/macros
import std/unicode
import std/strutils
import std/strformat
import std/typetraits
import px_engine/pxd/m_debug
import pods_d


const EndOfLine                 = {'\l', '\r'}
const CommentsOperator          = {'#'}
const SomeWhitespace            = {' ', '\t', '\v', '\r', '\l', '\f'}
const AssignmentOperators       = {'=', ':'}
const StringDelimeters          = {'\'', '"'}
const ObjectBeginDelimeters     = {'.', '('}
const ObjectEndDelimeters       = {';', ')'}
const ArrayBeginDelimeter       = {'['}
const ArraySeparator            = {','}
const ArrayEndDelimeter         = {']'}
const PodDigits*                = {'0'..'9', '-'}
const debug_tag                 = "POD"

proc toPodStringSparseHook(p: var PodWriter, pod: var Pod)
proc toPodStringDenseHook(p: var PodWriter, pod: var Pod)

var podConfigDefault*  = PodSettings()
podConfigDefault.style = PodStyle.Compact


#------------------------------------------------------------------------------------------
# @api pod utils
#------------------------------------------------------------------------------------------
proc numFields[T](x: T): int =
  for _ in x.fields:
    inc result


proc numFields[T](x: var T): int =
  for _ in x.fields:
    inc result

#------------------------------------------------------------------------------------------
# @api pod debug
#------------------------------------------------------------------------------------------
template error*(p: var PodReader, message: string) =
  raise newException(PodError, message)


template error*(p: var PodWriter, message: string) =
  raise newException(PodError, message)


proc podGetErrorMessage*(errorKind: PodErrorKind, args: varargs[string]): string =
  const ansi_black_bold = "\e[1;29m"
  const ansi_blue_bold  = "\e[1;34m"
  const ansi_default    = "\e[0;39m"
  case errorKind:
    of PodErrorKind.NoFile:
      result = &"{ansi_black_bold}[POD.IO]:{ansi_default} File with name {ansi_blue_bold}{args[0]}{ansi_default} doesn't exist."
    of PodErrorKind.NonConvertable:
      result = &"{ansi_black_bold}[POD.Serialization]:{ansi_default} No converter available for objects type of {ansi_blue_bold}[{args[0]}]{ansi_default}."
    of PodErrorKind.InvalidKey:
      result = &"{ansi_black_bold}[POD.Parse]:{ansi_default} Failed on [ {args[0]} ] ({args[1]})"
    of PodErrorKind.InvalidNodeKey:
      result = &"{ansi_black_bold}[POD.Parse]:{ansi_default} Failed on parse pod key. ({args[0]})"
    of PodErrorKind.InvalidTreeRootKey:
      result = &"{ansi_black_bold}[POD.Parse]:{ansi_default} In order to get PodObject, pod must derive from named root object."
    of PodErrorKind.InvalidNumber:
      result = &"{ansi_black_bold}[POD.Parse]:{ansi_default} The number of key can't be parsed. ({args[0]})"
    of PodErrorKind.UnknownValue:
      result = &"{ansi_black_bold}[POD.Parse]:{ansi_default} Unknown value. ({args[0]})"
    of PodErrorKind.InvalidStringEnding:
      result = &"{ansi_black_bold}[POD.Parse]:{ansi_default} The string doesn't have ending delimiter \". ({args[0]})"

template fatal*(errorKind: PodErrorKind, args: varargs[string]) =
  var message = podGetErrorMessage(errorKind, args)
  debug.fatal(message)


template fatal*(p: var PodReader, errorKind: PodErrorKind, args: varargs[string]) =
  var message = podGetErrorMessage(errorKind, args) & " (" & $p.charIndex & ")"
  debug.fatal(message)


#------------------------------------------------------------------------------------------
# @api pod parser
#------------------------------------------------------------------------------------------
when defined(release):
  {.push checks: off, inline.}


proc exceed*(p: var PodWriter, len: int): bool =
  let freeBufferLen = p.bufferLen - p.charIndex
  return freeBufferLen < len


proc initBuffer*(p: var PodWriter, len: int) =
  p.bufferLen = len
  p.buffer    = newString(len)
  p.depth     = 0


proc setLenBuffer*(p: var PodWriter, len: int) =
  p.bufferLen = len
  p.buffer.setLen(len)


proc add*(p: var PodWriter, c: char) =
  if p.bufferLen == p.charIndex:
    p.setLenBuffer(p.bufferLen * 2 + 1)
  p.buffer[p.charIndex] = c
  inc p.charIndex


proc add*(p: var PodWriter, key: string) =
  if p.exceed(key.len):
    p.setLenBuffer(p.bufferLen * 2 + key.len)
  for c in key:
    p.buffer[p.charIndex] = c
    inc p.charIndex


proc addIdent(p: var PodWriter) =
  for i in 0..<p.ident:
    p.add(' ')
proc addIdentDepth(p: var PodWriter) =
  for i in 0..<p.objDepth:
    p.add(' ')
    p.add(' ')

# 🔍 source: https://github.com/treeform/jsony/blob/master/src/jsony.nim
# Credits to Treeform for fast way of parsing ints.
const lookupDigits* = block:
  let s = """00010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899"""
  s


proc add*(p: var PodWriter, val: SomeUnsignedInt) =
  if val == 0:
    p.add('0')
    return
  var digits: array[20, char]
  var val = val
  var len = 0
  while 0 < val:
    let index = val mod 100
    digits[len] = lookupDigits[index*2+1]
    inc len
    digits[len] = lookupDigits[index*2]
    inc len
    val = val div 100
  if digits[len-1] == '0':
    dec len
  if p.exceed(len):
    p.setLenBuffer(p.bufferLen + len)
  dec len
  while 0 <= len:
    p.buffer[p.charIndex] = digits[len]
    dec len
    inc p.charIndex


proc skip*(p: var PodReader) =
  inc p.charIndex


proc skip*(p: var PodReader, step: int) =
  p.charIndex += step


proc canAdvance*(p: var PodReader): bool =
  p.charIndex < p.sourceLen


proc canAdvance*(p: var PodReader, step: int): bool =
  p.charIndex + step < p.sourceLen


proc peek*(p: var PodReader): char =
  p.source[p.charIndex]


proc peek*(p: var PodReader, step: int): char =
  p.source[p.charIndex + step]


proc getLineWidth*(p: var PodWriter): int =
  result 
 # while p.peek(-1) == ' ':
  #  result += 1


proc advance*(p: var PodReader): char =
  result = p.peek()
  p.skip()

proc advance*(p: var PodReader, step: int): char =
  result = p.peek(step)
  p.skip(step)


proc match*(p: var PodReader, chars: set[char]): bool =
  if p.advance() in chars:
    result = true
  else:
    result =false


proc skipWhitespaceUntilEndOfLine*(p: var PodReader) =
  const Whitespaces = {' ', '\t', '\v', '\f'}
  while p.canAdvance() and p.peek() in Whitespaces:
    p.skip()


proc skipUntilEndOfLine*(p: var PodReader) =
  while p.canAdvance() and p.peek() notin EndOfLine:
    p.skip()


proc skipWhitespace*(p: var PodReader) =
  while p.canAdvance():
    case p.peek():
      of SomeWhitespace:
        p.skip()
      of CommentsOperator:
        while p.canAdvance() and p.peek() notin EndOfLine:
          p.skip()
      else:
        break


proc skipSymbol*(p: var PodReader) =
  p.skipWhitespace()
  while p.canAdvance():
    let c = p.peek()
    case c:
      of SomeWhitespace, ArraySeparator, ObjectEndDelimeters, ArrayEndDelimeter:
        break
      else:
        p.skip()


proc skipSymbol*(p: var PodReader, symbols: set[char]) =
  p.skipWhitespace()
  if p.peek() in symbols:
    p.skip()
    return
  else:
    error(p,"Invalid symbol.")


proc skipSymbol*(p: var PodReader, symbol: char) =
  p.skipWhitespace()
  if p.peek() == symbol:
    p.skip()
    return
  else:
    error(p,"Invalid symbol.")


proc parseDigit*(p: var PodReader): int =
  const digits = {'0'..'9'}
  const zero   = '0'.ord
  template parseNumber() =
    while p.canAdvance:
      let c = p.peek()
      case c:
        of digits:
          result = (c.ord - zero + result * 10).int
          p.skip()
        of SomeWhitespace:
          break
        of ObjectEndDelimeters:
          break
        of ArrayEndDelimeter:
          break
        of ArraySeparator:
          break
        of StringDelimeters:
          break
        else:
          error(p,"Invalid value")
  case p.peek():
    of '-':
      p.skip()
      parseNumber()
      result = -result
    of digits:
      parseNumber()
    else:
      error(p,"Invalid value")


proc parseTokenString*(p: var PodReader) =
  var tokenLen = 0
  var tokenBeginIndex = p.charIndex
  while p.canAdvance():
    let c = p.peek()
    case c:
      of StringDelimeters:
        break
      else:
        inc tokenLen
    p.skip()
  p.token.setLen(tokenLen)
  if tokenLen > 0:
    let chars = cast[ptr UncheckedArray[char]](p.token[0].addr)
    for index in 0..<tokenLen:
      chars[index] = p.source[tokenBeginIndex+index]


proc parseTokenKey*(p: var PodReader) =
  var tokenLen = 0
  var tokenBeginIndex = p.charIndex
  while p.canAdvance():
    let c = p.peek()
    case c:
      of SomeWhitespace:
        break
      of AssignmentOperators:
        break
      else:
        inc tokenLen
    p.skip()
  p.token.setLen(tokenLen)
  if tokenLen > 0:
    let chars = cast[ptr UncheckedArray[char]](p.token[0].addr)
    for index in 0..<tokenLen:
      chars[index] = p.source[tokenBeginIndex+index]


proc parseTokenValue*(p: var PodReader) =
  var tokenLen = 0
  var tokenBeginIndex = p.charIndex
  while p.canAdvance():
    let c = p.peek()
    case c:
      of SomeWhitespace:
        break
      of ObjectEndDelimeters:
        break
      of ArrayEndDelimeter:
        break
      of ArraySeparator:
        break
      of StringDelimeters:
        break
      else:
        inc tokenLen
    p.skip()
  p.token.setLen(tokenLen)
  if tokenLen > 0:
    let chars = cast[ptr UncheckedArray[char]](p.token[0].addr)
    for index in 0..<tokenLen:
      chars[index] = p.source[tokenBeginIndex+index]


proc parseTokenObject*(p: var PodReader) =
  var tokenLen = 0
  var tokenBeginIndex = p.charIndex
  while p.canAdvance():
    let c = p.peek()
    case c:
      of SomeWhitespace:
        break
      of AssignmentOperators:
        break
      of ObjectBeginDelimeters:
        break
      of ObjectEndDelimeters:
        break
      of ArraySeparator:
        break
      else:
        inc tokenLen
    p.skip()
  p.token.setLen(tokenLen)
  if tokenLen > 0:
    let chars = cast[ptr UncheckedArray[char]](p.token[0].addr)
    for index in 0..<tokenLen:
      chars[index] = p.source[tokenBeginIndex+index]


proc eatObjBegin*(p: var PodReader) =
  if p.peek() notin ObjectBeginDelimeters:
    debug.fatal(debug_tag, "no object begining")
  else:
    p.skip()


proc eatArrayBegin*(p: var PodReader) =
  if p.peek() notin ArrayBeginDelimeter:
    debug.fatal(debug_tag,"no array begining")
  else:
    p.skip()


proc eatArrayEnd*(p: var PodReader) =
  if p.peek() notin ArrayEndDelimeter:
    debug.fatal(debug_tag,"no array ending")
  else:
    p.skip()


proc eatObjEnd*(p: var PodReader) =
  if p.peek() notin ObjectEndDelimeters:
    debug.fatal(debug_tag,"no object ending")
  else:
    p.skip()


when defined(release):
  {.pop.}


proc readPodFile*(path: string): string =
  if fileExists path:
    result = readFile(path)
  else: 
    result = ""


proc writePodFile*(path: string, obj: string) =
  writeFile(path,obj)


#---------------------------------------------------------------------------------------------
# @api pod object utils
#---------------------------------------------------------------------------------------------
proc add*(parent: var Pod, child: Pod) =
  parent.list.add(child)


proc setFlags*(self: var Pod, flags: varargs[int]) =
  self.flag = 0
  for flag in flags:
    self.flag = self.flag or flag.int32



#---------------------------------------------------------------------------------------------
# @api pod object constructors
#---------------------------------------------------------------------------------------------
proc initPod*(arg: int, flags: varargs[int]): Pod =
  result = Pod(kind: PInt, vint: arg)
  setFlags(result, flags)


proc initPod*(arg: float, flags: varargs[int]): Pod =
  result = Pod(kind: PFloat, vfloat: arg)
  setFlags(result, flags)


proc initPod*(arg: string, flags: varargs[int]): Pod =
  result = Pod(kind: PString, vstring: arg)
  setFlags(result, flags)


proc initPod*(arg: bool, flags: varargs[int]): Pod =
  result = Pod(kind: PBool, vbool: arg)
  setFlags(result, flags)


proc initPod*(arg: pointer, flags: varargs[int]): Pod =
  result = Pod(kind: PPointer, vpointer: arg)
  setFlags(result, flags)


proc initPodArray*(flags: varargs[int]): Pod =
  result = Pod(kind: PArray)
  setFlags(result, flags)


proc initPodObject*(flags: varargs[int]): Pod =
  result = Pod(kind: PObject)
  setFlags(result, flags)


# proc initPodTable*(flags: varargs[int]): Pod =
#   result = Pod(kind: PTable)
#   setFlags(result, flags)

#---------------------------------------------------------------------------------------------
# @api pod object getters
#---------------------------------------------------------------------------------------------
proc hasKey*(self: var Pod, key: string): bool =
  for ch in key:
    if ch == '.':
      let keys = key.split('.')
      var nvar = self.addr
      for index in 0..keys.high:
        let nkey = keys[index]
        if not nvar.fields.hasKey(nkey):
          return false
        else:
          nvar = nvar.fields[nkey].addr
      return true
  if not self.fields.hasKey(key):
    return false
  result = true


proc hasKey*(self: ptr Pod, key: string): bool =
  for ch in key:
    if ch == '.':
      let keys = key.split('.')
      var nvar = self
      for index in 0..keys.high:
        let nkey = keys[index]
        if not nvar.fields.hasKey(nkey):
          return false
        else:
          nvar = nvar.fields[nkey].addr
      return true
  if not self.fields.hasKey(key):
    return false
  result = true


proc getChild*(self: var Pod, key: string): var Pod =
  if not self.fields.hasKey(key):
    self.fields[key] = initPodObject()
  self.fields[key]


proc `[]`*(self: var Pod, key: string): var Pod =
  for ch in key:
    if ch == '.':
      let keys = key.split('.')
      var nvar = self.addr
      for index in 0..keys.high:
        let nkey = keys[index]
        if not nvar.fields.hasKey(nkey):
          nvar.fields[nkey] = initPodObject()
          nvar.fields[nkey].flag = nvar.flag
        nvar = nvar.fields[nkey].addr
      return nvar[]
  if not self.fields.hasKey(key):
    self.fields[key] = initPodObject()
    self.fields[key].flag = self.flag
  self.fields[key]


proc `[]`*(self: var Pod, key: int): var Pod =
  self.list[key]


proc `[]=`*(self: var Pod, key: string, val: var Pod) =
  for ch in key:
    if ch == '.':
      var keys = key.split('.')
      var nvar = self.addr
      for index in 0..keys.high:
        let nkey = keys[index]
        if not nvar.fields.hasKey(nkey):
          nvar.fields[nkey] = initPodObject()
          nvar.fields[nkey].flag = nvar.flag
        nvar = nvar.fields[nkey].addr
      nvar[] = val
      return
  self.fields[key] = val


proc `[]=`*(self: var Pod, key: string, val: Pod) =
  for ch in key:
    if ch == '.':
      var keys = key.split('.')
      var nvar = self.addr
      for index in 0..keys.high:
        let nkey = keys[index]
        if not nvar.fields.hasKey(nkey):
          nvar.fields[nkey] = initPodObject()
          nvar.fields[nkey].flag = nvar.flag
        nvar = nvar.fields[nkey].addr
      nvar[] = val
      return
  self.fields[key] = val


proc valPtr*(self: var Pod, typeof: typedesc[bool]): ptr bool =
  result = self.vbool.addr


proc valPtr*(self: var Pod, typeof: typedesc[string]): ptr string =
  result = self.vstring.addr


proc valPtr*(self: var Pod, typeof: typedesc[SomeInteger]): ptr typeof =
  result = cast[ptr typeof](self.vint.addr)


proc valPtr*(self: var Pod, typeof: typedesc[SomeFloat]): ptr typeof =
  result = cast[ptr typeof](self.vfloat.addr)


proc valPtr*[T](self: var Pod, typeof: typedesc[T]): ptr typeof =
  result = cast[ptr typeof](self.vpointer)


proc val*(self: var Pod, typeof: typedesc[bool]): bool =
  result = self.vbool


proc val*(self: var Pod, typeof: typedesc[string]): string =
  result = self.vstring


proc val*(self: var Pod, typeof: typedesc[SomeInteger]): typeof =
  result = cast[typeof](self.vint)


proc val*(self: var Pod, typeof: typedesc[SomeFloat]): typeof =
  result = cast[typeof](self.vfloat)


proc val*[T](self: var Pod, typeof: typedesc[T]): typeof =
  result = cast[T](self.vpointer)


proc checkFlag*(self: var Pod, flag: int): bool =
  result = (self.flag and flag) != 0


#--------------------------------------------------------------------------------------------
# @api pod object from pod
#---------------------------------------------------------------------------------------------
proc fromPodHook*[T: bool](pod: var Pod, result: var T)
proc fromPodHook*[T: string](pod: var Pod, result: var T)
proc fromPodHook*[T: SomeFloat](pod: var Pod, result: var T)
proc fromPodHook*[T: SomeInteger](pod: var Pod, result: var T)
proc fromPodHook*[T: object](pod: var Pod, result: var T)
proc fromPodHook*[T: tuple](pod: var Pod, result: var T)
proc fromPodHook*[T](pod: var Pod, obj: var seq[T])
proc fromPodHook*[T](pod: var Pod, obj: var openArray[T])
proc fromPodHook*[K,V](pod: var Pod, obj: var Table[K,V])
proc fromPodHook*[K,V](pod: var Pod, obj: var OrderedTable[K,V])


proc fromPodHook*[K,V](pod: var Pod, obj: var OrderedTable[K,V]) =
  for k, v in pod.fields.mpairs:
    var pitem: V
    fromPodHook(v, pitem)
    obj[k] = pitem


proc fromPodHook*[K,V](pod: var Pod, obj: var Table[K,V]) =
  for k, v in pod.fields.mpairs:
    var pitem: V
    fromPodHook(v, pitem)
    obj[k] = pitem


proc fromPodHook*[T](pod: var Pod, obj: var openArray[T]) =
  for index, item in pod.list.mpairs:
    var pitem: T
    fromPodHook(item, pitem)
    obj[index] = pitem


proc fromPodHook*[T](pod: var Pod, obj: var seq[T]) =
  for item in pod.list.mitems:
    var pitem: T
    fromPodHook(item, pitem)
    obj.add(pitem)


proc fromPodHook*[T: bool](pod: var Pod, result: var T) =
  result = pod.vbool


proc fromPodHook*[T: string](pod: var Pod, result: var T) =
  result = pod.vstring


proc fromPodHook*[T: SomeFloat](pod: var Pod, result: var T) =
  if pod.kind == PInt:
    result = (typeof(result))pod.vint
  else:
    result = pod.vfloat


proc fromPodHook*[T: SomeInteger](pod: var Pod, result: var T) =
  result = (typeof(result))pod.vint


proc fromPodHook*[T: object](pod: var Pod, result: var T) =
  for fkey, fval in result.fieldPairs:
    if pod.hasKey(fkey):
      fromPodHook(pod[fkey], fval)


proc fromPodHook*[T: tuple](pod: var Pod, result: var T) =
  if T.isNamedTuple():
    for fkey, fval in result.fieldPairs:
      if pod.hasKey(fkey):
        fromPodHook(pod[fkey], fval)
  else:
    var index = 0
    for fval in result.fields:
      if pod.list.len > index:
        fromPodHook(pod.list[index], fval)
      inc index
   
proc fromPod*(pod: var Pod, typeof: typedesc): typeof =
  fromPodHook(pod, result)

#-----------------------------------------------------------------------------------------------------------------------------------------
# @api pod object to pod
#-----------------------------------------------------------------------------------------------------------------------------------------
proc toPodHook*[T: openArray](pod: var Pod, obj: T)
proc toPodHook*[T: bool](pod: var Pod, obj: T)
proc toPodHook*[T: string](pod: var Pod, obj: T)
proc toPodHook*[T: SomeFloat](pod: var Pod, obj: T)
proc toPodHook*[T: SomeInteger](pod: var Pod, obj: T)
proc toPodHook*[T: object | ref object](pod: var Pod, obj: T)
proc toPodHook*[T: tuple](pod: var Pod, obj: T)
proc toPodHook*[K,V](pod: var Pod, obj: Table[K,V])
proc toPodHook*[K,V](pod: var Pod, obj: OrderedTable[K,V])


proc toPodHook*[K,V](pod: var Pod, obj: OrderedTable[K,V]) =
  pod = initPodObject()
  pod.isTable = true
  for k,v in obj.pairs:
    toPodHook(pod[k], v)


proc toPodHook*[K,V](pod: var Pod, obj: Table[K,V]) =
  pod = initPodObject()
  pod.isTable = true
  for k,v in obj.pairs:
    toPodHook(pod[k], v)


proc toPodHook*[T: openArray](pod: var Pod, obj: T) =
  pod = initPodArray()
  for item in obj.items:
    var pitem: Pod
    toPodHook(pitem, item)
    pod.list.add(pitem)


proc toPodHook*[T: bool](pod: var Pod, obj: T) =
  pod = initPod(obj)


proc toPodHook*[T: string](pod: var Pod, obj: T) =
  pod = initPod(obj)


proc toPodHook*[T: SomeFloat](pod: var Pod, obj: T) =
  pod = initPod((float)obj)


proc toPodHook*[T: SomeInteger](pod: var Pod, obj: T) =
  pod = initPod((int)obj)


proc toPodHook*[T: object | ref object](pod: var Pod, obj: T) =
  pod = initPodObject()
  for k, v in obj.fieldPairs:
    toPodHook(pod[k], v)


proc toPodHook*[T: tuple](pod: var Pod, obj: T) =
  if T.isNamedTuple():
    pod = initPodObject()
    for fkey, fval in obj.fieldPairs:
      toPodHook(pod[fkey], fval)
  else:
    pod = initPodArray()
    for fval in obj.fields:
      var item: Pod
      toPodHook(item, fval)
      pod.add(item)


proc toPod*[T](obj: T): Pod =
  toPodHook(result, obj)

#---------------------------------------------------------------------------------------------
# @api pod object serialization
#---------------------------------------------------------------------------------------------
#todo: chore and refactor toPodString, feels ugly and not readable


proc toPodStringCompactHook(p: var PodWriter, pod: var Pod) =
  if checkFlag(pod, POD_DONT_SAVE):
    return
  proc addIdent(p: var PodWriter) =
    for i in 0..<p.ident:
      p.add(' ')
  proc parseArray(p: var PodWriter, pod: var Pod) =
    if checkFlag(pod, POD_DONT_SAVE):
      return
    var step = 0
    p.add('[')
    for fvalue in pod.list.mitems:
      if checkFlag(fvalue, POD_DONT_SAVE):
        continue
      if step > 0:
        p.add(',')
      p.toPodStringCompactHook(fvalue)
      inc step
    p.add(']')
  proc parseObject(p: var PodWriter, pod: var Pod) =
    if checkFlag(pod, POD_DONT_SAVE):
      return
    var step = 0
    p.add('(')
    for fkey, fvalue in pod.fields.mpairs:
      if checkFlag(fvalue, POD_DONT_SAVE):
        continue
      if step > 0:
        p.add(',')
      p.add(fkey)
      p.add('=')
      p.toPodStringCompactHook(fvalue)
      inc step
    p.add(')')
  proc parseTable(p: var PodWriter, pod: var Pod) =
    if checkFlag(pod, POD_DONT_SAVE):
      return
    var step = 0
    p.add("[[")
    for fkey, fvalue in pod.fields.mpairs:
      if checkFlag(fvalue, POD_DONT_SAVE):
        continue
      if step > 0:
        p.add(',')
      p.add('\'')
      p.add(fkey)
      p.add('\'')
      p.add('=')
      p.toPodStringCompactHook(fvalue)
      inc step
    p.add("]]")
  case pod.kind:
    of PObject:
      if pod.isTable:
        p.parseTable(pod)
      else:
        p.parseObject(pod)
    of PArray:
      p.parseArray(pod)
    of PString:
      p.add('\'')
      p.add(pod.vstring)
      p.add('\'')
    of PInt:
      p.add($pod.vint)
    of PFloat:
      p.add(pod.vfloat.formatFloat(ffDefault, -1))
    of PBool:
      p.add($pod.vbool)
    of PPointer:
      p.add("null")


proc toPodStringSparseArrayed(p: var PodWriter, pod: var Pod) =
  if checkFlag(pod, POD_DONT_SAVE):
    return
  proc parseArray(p: var PodWriter, pod: var Pod) =
    if checkFlag(pod, POD_DONT_SAVE):
      return
    var step = 0
    inc p.objDepth
    p.add('[')
    p.add('\n')
    for fvalue in pod.list.mitems:
      if checkFlag(fvalue, POD_DONT_SAVE):
        continue
      if step > 0:
        p.add(',')
        p.add('\n')
      p.addIdentDepth()
      p.toPodStringSparseArrayed(fvalue)
      inc step
    p.add('\n')
    dec p.objDepth
    p.addIdentDepth()
    p.add(']')
  proc parseObject(p: var PodWriter, pod: var Pod) =
    if checkFlag(pod, POD_DONT_SAVE):
      return
    inc p.objDepth
    var step  = 0
    var lined = 0
    p.add('(')
    p.add('\n')
    p.addIdentDepth()
    for fkey, fvalue in pod.fields.mpairs:
      if checkFlag(fvalue, POD_DONT_SAVE):
        continue
      if step > 0:
        p.add('\n')
        p.addIdentDepth()
      else:
        for fkey in pod.fields.keys:
          if fkey.len > lined:
            lined = fkey.len
      p.add(fkey)
      var lineDelta = lined - fkey.len
      for i in 0..<lineDelta:
        p.add(' ')
      p.add(' ')
      p.add('=')
      p.add(' ')
      p.toPodStringCompactHook(fvalue)
      inc step
    p.add('\n')
    dec p.objDepth
    p.addIdentDepth()
    p.add(')')
  proc parseTable(p: var PodWriter, pod: var Pod) =
    if checkFlag(pod, POD_DONT_SAVE):
      return
    inc p.objDepth
    var step = 0
    p.add("[[\n")
    p.addIdentDepth()
    var lined = 0
    if step == 0:
      for fkey in pod.fields.keys:
        if fkey.len > lined:
          lined = fkey.len
    for fkey, fvalue in pod.fields.mpairs:
      if checkFlag(fvalue, POD_DONT_SAVE):
        continue
      if step > 0:
        p.add('\n')
        p.addIdentDepth()
      p.add('\'')
      p.add(fkey)
      p.add('\'')
      var lineDelta = lined - fkey.len
      for i in 0..<lineDelta:
        p.add(' ')
      p.add(' ')
      p.add('=')
      p.add(' ')
      p.toPodStringSparseArrayed(fvalue)
      inc step
    p.add('\n')
    dec p.objDepth
    p.addIdentDepth()
    p.add("]]")
  case pod.kind:
    of PObject:
      if pod.isTable:
        p.parseTable(pod)
      else:
        p.parseObject(pod)
    of PArray:
      p.parseArray(pod)
    of PString:
      p.add('\'')
      p.add(pod.vstring)
      p.add('\'')
    of PInt:
      p.add($pod.vint)
    of PFloat:
      p.add(pod.vfloat.formatFloat(ffDefault, -1))
    of PBool:
      p.add($pod.vbool)
    of PPointer:
      p.add("null")


proc toPodStringSparseHook(p: var PodWriter, pod: var Pod) =
  if checkFlag(pod, POD_DONT_SAVE):
    return
  proc parseArray(p: var PodWriter, pod: var Pod) =
    var step = 0
    inc p.objDepth
    p.add('[')
    p.add('\n')
    for fvalue in pod.list.mitems:
      if checkFlag(fvalue, POD_DONT_SAVE):
        continue
      if step > 0:
        p.add(',')
        p.add('\n')
      p.addIdentDepth()
      p.toPodStringSparseArrayed(fvalue)
      inc step
    p.add('\n')
    dec p.objDepth
    p.addIdentDepth()
    p.add(']')
  proc parseObject(p: var PodWriter, pod: var Pod) =
    if checkFlag(pod, POD_DONT_SAVE):
        return
    var step = 0
    if p.objDepth == 0:
      p.ident = 2
      p.add("(\n")
      p.addIdent()
    else:
      p.add(".")
    inc p.objDepth
    for fkey, fvalue in pod.fields.mpairs:
      if checkFlag(fvalue, POD_DONT_SAVE):
        continue
      if step > 0:
        for i in 0..<p.objDepth-1:
          p.add(";")
        p.add("\n")
        p.addIdent()
        for v in p.tokens:
          p.add(v)
          p.add(".")
      p.add(fkey)
      #if fvalue.kind != PObject:
      p.add(" = ")
      p.tokens.add(fkey)
      p.toPodStringSparseArrayed(fvalue)
      p.tokens.del(p.tokens.high)
      inc step
    dec p.objDepth
    if p.objDepth == 0:
      p.add("\n)")
    else:
      p.add(";")
  proc parseTable(p: var PodWriter, pod: var Pod) =
    if checkFlag(pod, POD_DONT_SAVE):
        return
    var step = 0
    if p.objDepth == 0:
      p.ident = 2
      p.add("[[\n")
      p.addIdent()
    else:
      p.add(".")
    inc p.objDepth
    for fkey, fvalue in pod.fields.mpairs:
      if checkFlag(fvalue, POD_DONT_SAVE):
        continue
      if step > 0:
        for i in 0..<p.objDepth-1:
          p.add(";")
        p.add("\n")
        p.addIdent()
        for v in p.tokens:
          p.add(v)
          p.add(".")
      p.add('\'')
      p.add(fkey)
      p.add('\'')
      p.add(" = ")
      p.tokens.add(fkey)
      p.toPodStringSparseArrayed(fvalue)
      p.tokens.del(p.tokens.high)
      inc step
    dec p.objDepth
    if p.objDepth == 0:
      p.add("\n]]")
    else:
      p.add(";")
  case pod.kind:
    of PObject:
      if pod.isTable:
        p.parseTable(pod)
      else:
        p.parseObject(pod)
    of PArray:
      p.parseArray(pod)
    of PString:
      p.add('\'')
      p.add(pod.vstring)
      p.add('\'')
    of PInt:
      p.add($pod.vint)
    of PFloat:
      p.add(pod.vfloat.formatFloat(ffDefault, -1))
    of PBool:
      p.add($pod.vbool)
    of PPointer:
      p.add("null")


proc toPodStringDenseHook(p: var PodWriter, pod: var Pod) =
  if checkFlag(pod, POD_DONT_SAVE):
    return
  proc parseArray(p: var PodWriter, pod: var Pod) =
    var step = 0
    inc p.objDepth
    p.add('[')
    p.add('\n')
    for fvalue in pod.list.mitems:
      if checkFlag(fvalue, POD_DONT_SAVE):
        continue
      if step > 0:
        p.add(',')
        p.add('\n')
      p.addIdentDepth()
      p.toPodStringCompactHook(fvalue)
      inc step
    p.add('\n')
    dec p.objDepth
    p.addIdentDepth()
    p.add(']')
  proc parseObject(p: var PodWriter, pod: var Pod) =
    if checkFlag(pod, POD_DONT_SAVE):
        return
    var step = 0
    if p.objDepth == 0:
      p.ident = 2
      p.add("(\n")
      p.addIdent()
    else:
      p.add(".")
    inc p.objDepth
    for fkey, fvalue in pod.fields.mpairs:
      if checkFlag(fvalue, POD_DONT_SAVE):
        continue
      if step > 0:
        for i in 0..<p.objDepth-1:
          p.add(";")
        p.add("\n")
        p.addIdent()
        for v in p.tokens:
          p.add(v)
          p.add(".")
      p.add(fkey)
      if fvalue.kind != PObject:
        p.add(" = ")
      p.tokens.add(fkey)
      p.toPodStringDenseHook(fvalue)
      p.tokens.del(p.tokens.high)
      inc step
    dec p.objDepth
    if p.objDepth == 0:
      p.add("\n)")
    else:
      p.add(";")
  proc parseTable(p: var PodWriter, pod: var Pod) =
    if checkFlag(pod, POD_DONT_SAVE):
        return
    var step = 0
    if p.objDepth == 0:
      p.ident = 2
      p.add("(\n")
      p.addIdent()
    else:
      p.add(".")
    inc p.objDepth
    for fkey, fvalue in pod.fields.mpairs:
      if checkFlag(fvalue, POD_DONT_SAVE):
        continue
      if step > 0:
        for i in 0..<p.objDepth-1:
          p.add(";")
        p.add("\n")
        p.addIdent()
        for v in p.tokens:
          p.add(v)
          p.add(".")
      p.add(fkey)
      if fvalue.kind != PObject:
        p.add(" = ")
      p.tokens.add(fkey)
      p.toPodStringSparseArrayed(fvalue)
      p.tokens.del(p.tokens.high)
      inc step
    dec p.objDepth
    if p.objDepth == 0:
      p.add("\n)")
    else:
      p.add(";")
  case pod.kind:
    of PObject:
      p.parseObject(pod)
    of PArray:
      p.parseArray(pod)
    of PString:
      p.add('\'')
      p.add(pod.vstring)
      p.add('\'')
    of PInt:
      p.add($pod.vint)
    of PFloat:
      p.add(pod.vfloat.formatFloat(ffDefault, -1))
    of PBool:
      p.add($pod.vbool)
    of PPointer:
      p.add("null")


proc toPodString*(pod: var Pod, podSettings: var PodSettings = podConfigDefault): string =
  const bufferLen = 64
  var p: PodWriter
  p.initBuffer(bufferLen)
  p.ident = 2
  p.depth = 0
  case podSettings.style:
    of PodStyle.Compact:
      toPodStringCompactHook(p, pod)
    of PodStyle.Sparse:
      toPodStringSparseHook(p, pod)
    of PodStyle.Dense:
      toPodStringDenseHook(p, pod)
  p.setLenBuffer(p.charIndex)
  p.buffer


proc toPodString*(pod: Pod, podSettings: PodSettings = podConfigDefault): string =
  var refPod      = pod
  var refSettings = podSettings
  toPodString(refPod, refSettings)


proc toPodFile*(path: string, pod: Pod, podSettings: PodSettings = podConfigDefault) =
  var podstring = toPodString(pod, podSettings)
  writePodFile(path, podstring)




#--------------------------------------------------------------------------------------------
# @api pod object deserialization
#---------------------------------------------------------------------------------------------
proc merge*(parent: var Pod, child: var Pod) =
  parent.flag = parent.flag and child.flag
  case parent.kind:
    of PPointer:
      if child.kind == PPointer:
        parent.vpointer = child.vpointer
    of PInt:
      if child.kind == PInt:
        parent.vint = child.vint
    of PFloat:
      if child.kind == PFloat:
        parent.vfloat = child.vfloat
    of PString:
      if child.kind == PString:
        parent.vstring = child.vstring
    of PBool:
      if child.kind == PBool:
        parent.vbool = child.vbool
    of PArray:
      if child.kind == PArray:
        parent.list = child.list
    of PObject:
      if child.kind == PObject:
        parent.isTable = child.isTable
        for k, v in child.fields.mpairs:
          if parent.fields.hasKey(k):
            parent.fields[k].merge(v)
          else:
            parent[k] = child.fields[k]


proc merge*(parent: var Pod, child: Pod) =
  parent.flag = parent.flag and child.flag
  case parent.kind:
    of PInt:
      if child.kind == PInt:
        parent.vint = child.vint
    of PFloat:
      if child.kind == PFloat:
        parent.vfloat = child.vfloat
    of PString:
      if child.kind == PString:
        parent.vstring = child.vstring
    of PBool:
      if child.kind == PBool:
        parent.vbool = child.vbool
    of PArray:
      if child.kind == PArray:
        for index, item in child.list.pairs:
          if parent.list.len <= index:
            parent.add(item)
          elif parent.list[index].kind == item.kind:
            parent.list[index] = item
          else:
            parent.add(item)
    of PPointer:
        parent.vpointer = child.vpointer
    of PObject:
      if child.kind == PObject:
        parent.isTable = child.isTable
        for k, v in child.fields.pairs:
          if parent.fields.hasKey(k):
            parent.fields[k].merge(v)
          else:
            parent[k] = child.fields[k]


proc fromPodStringHook*(p: var PodReader, pod: var Pod) =
  proc parseString(p: var PodReader, pod: var Pod) =
    p.skip()
    p.parseTokenString()
    pod = initPod(p.token)
    p.skip()

  proc parseDigit(p: var PodReader, pod: var Pod) =
    p.parseTokenValue()
    try:
      pod = initPod(parseInt(p.token))
    except ValueError:
      try:
        pod = initPod(parseFloat(p.token))
      except ValueError:
        debug.fatal(debug_tag,"invalid digit value")

  proc parseTableKey(p: var PodReader) =
    p.skipWhitespace()
    if p.peek() in StringDelimeters:
      p.skip()
      p.parseTokenString()
      p.skip()
    else:
      p.parseTokenValue()
    p.skipWhitespace()
  
  proc parseTable(p: var PodReader, pod: var Pod) =
    pod = initPodObject()
    pod.isTable = true
    while p.canAdvance():
      p.parseTableKey()
      case p.peek():
        of AssignmentOperators:
          p.skip()
          p.skipWhitespace()
          p.fromPodStringHook(pod[p.token])
          p.skipWhitespace()
          if p.peek() in ArrayEndDelimeter:
            break
        of ArraySeparator:
          p.skip()
        of ArrayEndDelimeter:
          break
        else:
          debug.fatal(debug_tag,"invalid table assignment")
    p.skip()

  proc parseArray(p: var PodReader, pod: var Pod) =
    pod = initPodArray()
    while p.canAdvance():
      var item: Pod
      p.fromPodStringHook(item)
      pod.add(item)
      case p.peek():
        of ArraySeparator:
          p.skip()
        else:
          break

  proc parseArrayBody(p: var PodReader, pod: var Pod) =
    p.skip()
    p.skipWhitespace()
    if p.peek() in StringDelimeters:
      p.skip()
      p.parseTable(pod)
    elif p.peek() in ArrayBeginDelimeter:
      p.skip()
      p.parseTable(pod)
    else:
      p.parseArray(pod)
    p.skipWhitespace()
    p.eatArrayEnd()

  proc parseObject(p: var PodReader, pod: var Pod) =
    if pod.kind != PObject: pod = initPodObject()
    p.skip()
    var assigns = 0
    while p.canAdvance():
      p.skipWhitespace()
      p.parseTokenObject()
      p.skipWhitespace()
      case p.peek():
        of AssignmentOperators:
          inc assigns
          p.skip()
          p.skipWhitespace()
          p.fromPodStringHook(pod[p.token])
          p.skipWhitespace()
        of ObjectBeginDelimeters:
          p.skipWhitespace()
          p.fromPodStringHook(pod[p.token])
          p.skipWhitespace()
        of ObjectEndDelimeters:
          if assigns == 0 and p.token.len > 0:
            debug.fatal(debug_tag,"key without value")
          break
        of ArraySeparator:
          p.skip()
        else:
          break
    p.skipWhitespace()
    p.eatObjEnd()

  p.skipWhitespace()
  while p.canAdvance():
    case p.peek():
      of ObjectBeginDelimeters:
        p.parseObject(pod)
        break
      of ArrayBeginDelimeter:
        p.parseArrayBody(pod)
        break
      of StringDelimeters:
        p.parseString(pod)
        break
      of PodDigits:
        p.parseDigit(pod)
        break
      of 'f':
        if p.peek(4) == 'e':
          pod = initPod(false)
          p.skip(5)
          break
        else:
          debug.fatal(debug_tag,"wrong boolean")
      of 't':
        if p.peek(3) == 'e':
          pod = initPod(true)
          p.skip(4)
          break
        else:
          debug.fatal(debug_tag,"wrong boolean")
      of 'o':
        if p.peek(1) == 'n':
          pod = initPod(true)
          p.skip(2)
          break
        elif p.peek(2) == 'f':
          pod = initPod(false)
          p.skip(3)
          break
        else:
          debug.fatal(debug_tag,"wrong boolean")
      of 'n':
        if p.peek(3) == 'l':
          pod = initPod(nil)
          p.skip(4)
          break
        else:
          debug.fatal(debug_tag,"wrong null")
      else:
          debug.fatal("no value")
          break
    p.skip()
  p.skipWhitespace()


proc fromPodString*(podSource: string): Pod =
  var p: PodReader
  var srcref = podSource
  p.source = cast[ptr UncheckedArray[char]](srcref[0].addr)
  p.sourceLen = podSource.len
  result      = initPodObject()
  p.fromPodStringHook(result)


proc fromPodString*(podSource: string, pod: var Pod) =
  var npod = fromPodString(podSource)
  pod.merge(npod)


proc fromPodFile*(filePath: string): Pod =
  var podSource = readPodFile(filePath)
  result = fromPodString(podSource)


proc fromPodFile*(filePath: string, pod: var Pod) =
  var npod: Pod = fromPodFile(filePath)
  pod.merge(npod)


when defined(release):
  {.push checks: off, inline.}
#---------------------------------------------------------------------------------------------
# @api pod writer declaration
#---------------------------------------------------------------------------------------------
proc toPodStringHook[T: object](p: var PodWriter, val: T)
proc toPodStringHook[T: tuple] (p: var PodWriter, val: T)
proc toPodStringHook[T]        (p: var PodWriter, val: (SomeSet[T] | set[T]))
proc toPodStringHook[T]        (p: var PodWriter, val: seq[T])
proc toPodStringHook[K,V]      (p: var PodWriter, val: Table[K,V])
proc toPodStringHook[K,V]      (p: var PodWriter, val: OrderedTable[K,V])
proc toPodStringHook[K,V]      (p: var PodWriter, val: array[K,V])
proc toPodStringHook[T: enum]  (p: var PodWriter, val: T) 
proc toPodStringHook(p: var PodWriter, val: bool)
proc toPodStringHook(p: var PodWriter, val: char)
proc toPodStringHook(p: var PodWriter, val: string)
proc toPodStringHook(p: var PodWriter, val: SomeInteger)
proc toPodStringHook(p: var PodWriter, val: SomeFloat)


#---------------------------------------------------------------------------------------------
# @api pod writer serialization
#---------------------------------------------------------------------------------------------
template toPodKey*(p: var PodWriter, val: string) =
  p.add(val)


proc toPodStringHook(p: var PodWriter, val: bool) =
  if val:
    p.add("true")
  else:
    p.add("false")


proc toPodStringHook[T: enum](p: var PodWriter, val: T) =
  p.add('\'')
  p.add($val)
  p.add('\'')


proc toPodStringHook(p: var PodWriter, val: char) =
  p.add('\'')
  p.add(val)
  p.add('\'')


proc toPodStringHook(p: var PodWriter, val: SomeInteger) =
  if val < 0:
    p.add('-')
    p.add(0.uint64 - val.uint64)
  else:
    p.add(val.uint64)


proc toPodStringHook(p: var PodWriter, val: SomeFloat) =
  p.add($val)


proc toPodStringHook[T: tuple](p: var PodWriter, val: T) =
  var memberCount = 0
  p.add '('
  when T.isNamedTuple():
    for fkey, fval in val.fieldPairs:
      if memberCount > 0:
        p.add ','
      p.toPodKey(fkey)
      p.add ':'
      p.toPodStringHook(fval)
      inc memberCount
  else:
    for item in val.items:
      if memberCount > 0:
        p.add ','
      p.toPodStringHook(item)
      inc memberCount
  p.add ')'


proc toPodStringHook(p: var PodWriter, val: enum) =
  p.add('\'')
  p.add($val)
  p.add('\'')


proc toPodStringHook[T](p: var PodWriter, val: (SomeSet[T] | set[T])) =
  p.add '['
  var memberCount = 0
  for item in val:
    if 0 < memberCount:
      p.add ','
    p.toPodStringHook(item)
    inc memberCount
  p.add ']'


proc toPodStringHook[K,V](p: var PodWriter, val: Table[K,V]) =
  p.add "[["
  var memberCount = 0
  for key, item in val:
    if 0 < memberCount:
      p.add ','
    p.toPodStringHook(key)
    p.add " = "
    when compiles(p.toPodStringHook(item)):
      p.toPodStringHook(item)
    else:
      let itemType  = $item.type
      p.error(&"Can't parse element of type {itemType}")
    inc memberCount
  p.add "]]"


proc toPodStringHook[K,V](p: var PodWriter, val: OrderedTable[K,V]) =
  p.add "[["
  var memberCount = 0
  for key, item in val:
    if 0 < memberCount:
      p.add ','
    p.toPodStringHook(key)
    p.add ':'
    when compiles(p.toPodStringHook(item)):
      p.toPodStringHook(item)
    else:
      let itemType  = $item.type
      p.error(&"Can't parse element of type {itemType}")
    inc memberCount
  p.add "]]"


proc toPodStringHook[T](p: var PodWriter, val: seq[T]) =
  p.add '['
  for memberCount, item in val:
    if 0 < memberCount:
      p.add ','
    when compiles(p.toPodStringHook(item)):
      p.toPodStringHook(item)
    else:
      let itemType  = $item.type
      p.error(&"Can't parse element of type {itemType}")
  p.add ']'


proc toPodStringHook[K,V](p: var PodWriter, val: array[K,V]) =
  p.add '['
  var memberCount = 0
  for item in val:
    if memberCount != 0:
      p.add ','
    when compiles(p.toPodStringHook(item)):
      p.toPodStringHook(item)
    else:
      let itemType  = $item.type
      p.error(&"Can't parse element of type {itemType}")
    inc memberCount
  p.add ']'


proc toPodStringHook[T: object](p: var PodWriter, val: T) =
  var memberCount = 0
  p.add '('
  for fkey, fval in val.fieldPairs:
    if memberCount > 0:
      p.add ','
    p.toPodKey(fkey)
    if fval is Table or fval is ref Table:
      p.add '='
    elif fval is object or fval is ref object:
      discard
    else:
      p.add '='
    when compiles(p.toPodStringHook(fval)):
      p.toPodStringHook(fval)
    else:
      let fvalType  = $fval.type
      let fkeyLabel = fkey
      p.error(&"Can't parse \"{fkeyLabel}\" of type {fvalType}")
    inc memberCount
  p.add ')'


proc toPodStringHook(p: var PodWriter, val: string) =
  p.add('\'')
  p.add(val)
  p.add('\'')


proc toPodString*[T: not Pod](obj: var T): string =
  const defaultBufferLen = 64
  var p: PodWriter
  when compiles(p.toPodStringHook(obj)):
    p.initBuffer(defaultBufferLen)
    p.toPodStringHook(obj)
    p.setLenBuffer(p.charIndex)
    return p.buffer
  else:
    p.error(&"Can't parse object of type {$T}.")


#---------------------------------------------------------------------------------------------
# @api pod writer deserialization
#---------------------------------------------------------------------------------------------
proc fromPodStringHook*(p: var PodReader, result: var string)
proc fromPodStringHook*[T: SomeInteger](p: var PodReader, result: var T)
proc fromPodStringHook*[T: SomeFloat](p: var PodReader, result: var T)
proc fromPodStringHook*[T: bool](p: var PodReader, result: var T)
proc fromPodStringHook*[T: object](p: var PodReader, result: var T)
proc fromPodStringHook*[T: tuple](p: var PodReader, result: var T)
proc fromPodStringHook*[T](p: var PodReader, result: var seq[T])
proc fromPodStringHook*[I,T](p: var PodReader, result: var array[I,T])
proc fromPodStringHook*[K,V](p: var PodReader, result: var Table[K,V] | OrderedTable[K,V])
proc fromPodStringHook*[T: enum](p: var PodReader, result: var T)

proc fromPodStringHook*[T: enum](p: var PodReader, result: var T) =
  p.skipWhitespace()
  p.skip()
  p.parseTokenString()
  result = strutils.parseEnum[T](p.token)
  p.skip()
  p.skipWhitespace()


proc fromPodStringHook*[K,V](p: var PodReader, result: var Table[K,V] | OrderedTable[K,V]) =
  p.skipWhitespace()
  p.eatObjBegin()
  while p.canAdvance():
    p.skipWhitespace()
    p.parseTokenObject()
    p.skipWhiteSpace()
    case p.peek()
      of ObjectBeginDelimeters:
        if result.hasKey(p.token):
          p.fromPodStringHook(result[p.token])
        else:
          var v: V
          let k = p.token
          p.fromPodStringHook(v)
          result[k] = v
      of ArraySeparator:
        p.skip()
      of ObjectEndDelimeters:
        break
      else:
        discard
  p.skipWhitespace()
  p.eatObjEnd()


proc fromPodStringHook*[I,T](p: var PodReader, result: var array[I,T]) =
  p.skipWhiteSpace()
  if not p.match(ArrayBeginDelimeter):
     fatal("Array is not opened")
  p.skipWhitespace()
  var count = 0
  while p.canAdvance():
    case p.peek():
      of ArraySeparator:
        inc count
        p.skip()
      of ArrayEndDelimeter:
        break
      else:
         var item: T
         fromPodStringHook(p, item)
         result[count] = item
         p.skipWhiteSpace()
  p.skipWhiteSpace()
  if not p.match(ArrayEndDelimeter):
     fatal("Array is not closed")


proc fromPodStringHook*[T](p: var PodReader, result: var seq[T]) =
  p.skipWhiteSpace()
  if not p.match(ArrayBeginDelimeter):
     fatal("Array is not opened")
  result = @[]
  p.skipWhitespace()
  while p.canAdvance():
    case p.peek():
      of ArraySeparator:
        p.skip()
      of ArrayEndDelimeter:
        break
      else:
         var item: T
         fromPodStringHook(p, item)
         result.add(item)
         p.skipWhiteSpace()
  p.skipWhiteSpace()
  if not p.match(ArrayEndDelimeter):
     fatal("Array is not closed")


proc fromPodStringHook*[T: tuple](p: var PodReader, result: var T) = 
  if T.isNamedTuple():
    p.skipWhiteSpace()
    if not p.match(ObjectBeginDelimeters):
      fatal("Object is not opened")
    while p.canAdvance():
      p.skipWhitespace()
      p.parseTokenObject()
      p.skipWhitespace()
      case p.peek():
        of AssignmentOperators:
          p.skip()
          p.skipWhitespace()
          block injectValue:
            for fname, fvalue in result.fieldPairs:
              if fname == p.token:
                when compiles(fromPodStringHook(p, fvalue)):
                  fromPodStringHook(p, fvalue)
                else:
                  var typeof = $fvalue.typeof
                  fatal(&"can't parse object of type: {typeof}")
                break
          p.skipWhitespace()
        of ObjectBeginDelimeters:
          p.skipWhitespace()
          block injectValue:
            for fname, fvalue in result.fieldPairs:
              if fname == p.token:
                when compiles(fromPodStringHook(p, fvalue)):
                  fromPodStringHook(p, fvalue)
                else:
                  var typeof = $fvalue.typeof
                  fatal(&"can't parse object of type: {typeof}")
                break
          p.skipWhitespace()
          break
        of ArraySeparator:
          p.skip()
        of ObjectEndDelimeters:
          break
        else:
          break  

    p.skipWhiteSpace()
  
    if not p.match(ObjectEndDelimeters):
      fatal("Object is not closed")
  else:
    p.skipWhiteSpace()
    if not p.match(ArrayBeginDelimeter):
      fatal("Object is not opened")
    var count = 0
    let amount = numFields(result)
    for fval in result.fields:
      fromPodStringHook(p, fval)
      case p.peek():
          of ArraySeparator:
            inc count
            p.skip()
          of ArrayEndDelimeter:
            break
          else:
            break
      if count >= amount:
        while p.canAdvance():
          if p.peek in ArrayEndDelimeter:
            break
          p.skip()
        break 
    p.skipWhiteSpace()
    if not p.match(ArrayEndDelimeter):
      fatal("Object is not closed")


proc fromPodStringHook*[T: bool](p: var PodReader, result: var T) =
  p.skipWhiteSpace()
  proc throwError() =
    fatal("wrong boolean")
  case p.peek():
    of 'f':
      if p.peek(4) == 'e':
        result = false
        p.skip(5)
      else:
        throwError()
    of 't':
      if p.peek(3) == 'e':
        result = true
        p.skip(4)
      else:
        throwError()
    of 'o':
      if p.peek(1) == 'n':
        result = true
        p.skip(2)
      elif p.peek(2) == 'f':
        result = false
        p.skip(3)
      else:
        throwError()
    else:
      throwError()
  p.skipWhiteSpace()


proc fromPodStringHook*[T: SomeInteger](p: var PodReader, result: var T) =
  p.skipWhiteSpace()
  result = (T)p.parseDigit()
  p.skipWhiteSpace()


proc fromPodStringHook*[T: SomeFloat](p: var PodReader, result: var T) =
  p.skipWhiteSpace()
  p.parseTokenValue()
  try:
    result = (T)parseFloat(p.token)
  except ValueError:
    debug.fatal("not a float")
  p.skipWhiteSpace()


proc fromPodStringHook*(p: var PodReader, result: var string) =
  p.skipWhiteSpace()
  if not p.match(StringDelimeters):
    debug.fatal(debug_tag,"NOT A STRING")
  p.parseTokenString()
  result = p.token
  if not p.match(StringDelimeters):
    debug.fatal(debug_tag,"STRING IS NOT CLOSED")
  p.skipWhiteSpace()


proc fromPodStringHook[T: object](p: var PodReader, result: var T) =
  p.skipWhitespace()
  p.eatObjBegin()
  while p.canAdvance():
    p.skipWhitespace()
    p.parseTokenObject()
    p.skipWhitespace()
    block injectValue:
      for fname, fvalue in result.fieldPairs:
        if fname == p.token:
          case p.peek():
            of AssignmentOperators:
              p.skip()
              when compiles(fromPodStringHook(p, fvalue)):
                fromPodStringHook(p, fvalue)
              else:
                echo fname
                var t = $typeof(fvalue)
                debug.fatal(&"can't parse object of type: {t}")
            of ObjectBeginDelimeters:
              when compiles(fromPodStringHook(p, fvalue)):
                fromPodStringHook(p, fvalue)
              else:
                var t = $typeof(fvalue)
                debug.fatal(&"can't parse object of type: {t}")
            else:
              break
          break
    case p.peek():
      of ObjectBeginDelimeters:
        while p.canAdvance():
          if p.peek() in ObjectEndDelimeters:
            p.skip()
            break
          p.skip()
      of ObjectEndDelimeters:
        break
      of ArraySeparator:
        p.skip()
      else:
        discard
  p.eatObjEnd()
  p.skipWhitespace()
when defined(release):
  {.pop.}

proc fromPodString*[T: not Pod](podsource: string, typeof: typedesc[T]): typeof =
  var p: PodReader
  var podref = podsource
  p.source    = cast[ptr UncheckedArray[char]](podref[0].addr)
  p.sourceLen = podsource.len
  when compiles(fromPodStringHook(p, result)):
    fromPodStringHook(p, result)
  else:
    let t = $typeof
    fatal(&"can't parse object of type: {t}")