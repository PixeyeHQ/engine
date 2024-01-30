import px_pods
import std/[tables,macros,strformat,strutils,os]
import api
export tables

type
  Var* = ref object
    val*: pointer
const
  READONLY* = true


using api: VarsAPI
var varsPod*: Pod = initPodObject()


#------------------------------------------------------------------------------------------
# @api vars get/set
#------------------------------------------------------------------------------------------
proc source*(api;): var Pod =
  varsPod

proc get*(api; key: string, typeof: typedesc[Var]): Var =
  result = varsPod[key].val(typeof)


proc get*[T](api; key: string, typeof: typedesc[T]): ptr T =
  result = varsPod[key].valPtr(typeof)


proc put[T](self: ptr Pod, val: T, flags: varargs[int]) =
  self[] = initPod(val, flags)


proc put(self: ptr Pod, typeof: typedesc[Var], flags: varargs[int]) =
  self[] = initPod(cast[pointer](Var()), flags)


proc put*[T](api; key: string, val: T, flags: varargs[int]): ptr T {.discardable.} =
  var pod = varsPod[key].addr; put(pod, val, flags)
  result = pod[].valPtr(T)


proc call*(api; key: string) =
  let f = cast[proc(api: CommandsAPI){.nimcall.}](api.get(key, pointer))
  f(pxd.cmds)


proc call*[T](api; key: string, arg: T) =
  let f = cast[proc(api: CommandsAPI, a: T){.nimcall.}](api.get(key, pointer))
  f(pxd.cmds, arg)


proc call*[T,Y](api; key: string, arg: T, arg2: Y) =
  let f = cast[proc(api: CommandsAPI,  a: T, b: Y){.nimcall.}](api.get(key, pointer))
  f(pxd.cmds, arg, arg2)


proc put*(api; key: string, val: var Var, flags: varargs[int]): Var =
  var pod = varsPod[key]
  pod = initPod(cast[pointer](val), flags)
  result = val


proc has*(api; key: string): bool =
  varsPod.hasKey(key)


proc `[]`*(api; key: string): Pod =
  varsPod[key]
proc `[]`*(api; key: int): Pod =
  varsPod[key]
proc `[]=`*(api; key: string, val: Pod) =
  varsPod[key] = val


#------------------------------------------------------------------------------------------
# @api vars pointers
#------------------------------------------------------------------------------------------
proc wrap*[T](self: Var, arg: T) =
  self.val = cast[pointer](arg)


proc wrap*[T](self: Var, arg: var T) =
  self.val = cast[pointer](arg)


proc unwrap*[T](self: Var, typeof: typedesc[T]): T =
  result = cast[typeof](self.val)


#------------------------------------------------------------------------------------------
# @api vars io
#------------------------------------------------------------------------------------------
proc newVar*[T](api; arg: T): Var =
  result = Var()
  result.wrap(arg)


proc setFlags*(api; key: string, flags: varargs[int]) =
  px_pods.setFlags(varsPod[key], flags)


#------------------------------------------------------------------------------------------
# @api vars macro
#------------------------------------------------------------------------------------------
var callbackTableInt    = initTable[string, seq[proc(a,b: int)]]()
var callbackTableString = initTable[string, seq[proc(a,b: string)]]()
var callbackTableFloat  = initTable[string, seq[proc(a,b: float)]]()
var callbackTableBool   = initTable[string, seq[proc(a,b: bool)]]()


proc callCallbacks*(api: EngineAPI, key: string, a, b: int) {.inline.} =
  if callbackTableInt.hasKey(key):
    let callbacks = callbackTableInt[key]
    for cb in callbacks:
      cb(a,b)
proc callCallbacks*(api: EngineAPI, key: string, a, b: string) {.inline.} =
  if callbackTableString.hasKey(key):
    let callbacks = callbackTableString[key]
    for cb in callbacks:
      cb(a,b)
proc callCallbacks*(api: EngineAPI, key: string, a, b: float) {.inline.} =
  if callbackTableFloat.hasKey(key):
    let callbacks = callbackTableFloat[key]
    for cb in callbacks:
      cb(a,b)
proc callCallbacks*(api: EngineAPI, key: string, a, b: bool) {.inline.} =
  if callbackTableBool.hasKey(key):
    let callbacks = callbackTableBool[key]
    for cb in callbacks:
      cb(a,b)

## int
proc addCallback*(api; key: string, callback: proc(a,b: int)) =
  if not callbackTableInt.hasKey(key):
    callbackTableInt[key] = newSeq[proc(a,b: int)]()
  callbackTableInt[key].add(callback)
proc removeCallback*(api; key: string, callback: proc(a,b: int)) =
  if callbackTableInt.hasKey(key):
    callbackTableInt[key].delete(callbackTableInt[key].find(callback))
## float
proc addCallback*(api; key: string, callback: proc(a,b: float)) =
  if not callbackTableFloat.hasKey(key):
    callbackTableFloat[key] = newSeq[proc(a,b: float)]()
  callbackTableFloat[key].add(callback)
proc removeCallback*(api; key: string, callback: proc(a,b: float)) =
  if callbackTableFloat.hasKey(key):
    callbackTableFloat[key].delete(callbackTableFloat[key].find(callback))
## string
proc addCallback*(api; key: string, callback: proc(a,b: string)) =
  if not callbackTableString.hasKey(key):
    callbackTableString[key] = newSeq[proc(a,b: string)]()
  callbackTableString[key].add(callback)
proc removeCallback*(api; key: string, callback: proc(a,b: string)) =
  if callbackTableString.hasKey(key):
    callbackTableString[key].delete(callbackTableString[key].find(callback))
## bool
proc addCallback*(api; key: string, callback: proc(a,b: bool)) =
  if not callbackTableBool.hasKey(key):
    callbackTableBool[key] = newSeq[proc(a,b: bool)]()
  callbackTableBool[key].add(callback)
proc removeCallback*(api; key: string, callback: proc(a,b: bool)) =
  if callbackTableBool.hasKey(key):
    callbackTableBool[key].delete(callbackTableBool[key].find(callback))

macro gen*(api: VarsAPI, var_name: untyped, var_key: untyped, var_value: untyped, readonly: static bool = false) =
  proc getTemplate[T](p_name: string, k_name: string, v: T, vtype: typedesc[T], readonly: bool): string =
    var t = $vtype
    var vstr = ""
    if T is string:
      vstr = &""" "{v}" """
    else:
      vstr = &""" {v} """
    if readonly:
      result = &("""
let {p_name}_v = pxd.vars.put("{k_name}",{vstr})
proc {p_name}*(api: VarsAPI): {t} = {p_name}_v[]
      """)
    else:
      result = &("""
let {p_name}_v = pxd.vars.put("{k_name}",{vstr})
proc {p_name}*(api: VarsAPI): {t} = {p_name}_v[]
proc `{p_name}=`*(api: VarsAPI, arg: {t}) = 
  pxd.engine.callCallbacks("{k_name}",{p_name}_v[], arg)
  {p_name}_v[] = arg
        """)
  proc getTemplateProc[T](p_name: string, k_name: string, v: T, readonly: bool): string =
    var vstr = ""
    if T is string:
      vstr = &""" "{v}" """
    else:
      vstr = &""" {v} """
    if readonly:
      result = &("""
var {p_name}_v = pxd.vars.put("{k_name}", cast[pointer]({vstr}))
proc {p_name}*(api: VarsAPI): ptr pointer = {p_name}_v
      """)
    else:
      result = &("""
var {p_name}_v = pxd.vars.put("{k_name}", cast[pointer]({vstr}))
proc {p_name}*(api: VarsAPI): ptr pointer = {p_name}_v
proc `{p_name}=`*(api: VarsAPI, arg: ptr pointer) = {p_name}_v = arg
        """)

  var source: string
  let p_name = strval(var_name)
  let k_name = strval(var_key)
  let kind = var_value.kind
  case kind:
    of nnkStrLit:
      source = getTemplate(p_name, k_name, strval(var_value), string, readonly)
    of nnkIntLit:
      source = getTemplate(p_name, k_name, intVal(var_value), int, readonly)
    of nnkFloatLit:
      source = getTemplate(p_name, k_name, floatVal(var_value), float, readonly)
    of nnkIdent:
      let v = strVal(var_value)
      if v == "true" or v == "false":
        source = getTemplate(p_name, k_name, parseBool(v), bool, readonly)
      else:
        source = getTemplateProc(p_name, k_name, v, readonly)
    else:
      discard
  result = parsestmt(source)


macro gen*(api: VarsAPI, var_name: untyped, var_key: untyped, var_typedesc: untyped, var_value: untyped)  =
  var source: string
  let p_name = strval(var_name)
  let k_name = strval(var_key)
  let v = strVal(var_value)
  source = &("""
var {p_name}_v = pxd.vars.put("{k_name}", cast[pointer]({v}))
proc {p_name}*(api: VarsAPI): {var_typedesc} = cast[{var_typedesc}]({p_name}_v)
  """)
  result = parsestmt(source)