import std/tables
import pxd/api
import pxd/m_pods
import pxd/m_vars_d
export m_vars_d.VARS_DONT_SAVE

var varsPod: Pod
using api: VarsAPI


#------------------------------------------------------------------------------------------
# @api vars get/set
#------------------------------------------------------------------------------------------
proc get*(api; key: string, typeof: typedesc[Var]): Var =
  result = varsPod[key].val(typeof)


proc get*[T](api; key: string, typeof: typedesc[T]): ptr T =
  result = varsPod[key].valPtr(typeof)


proc put[T](self: var Pod, val: T, flags: varargs[int]) =
  self = pxd.pods.initPod(val, flags)


proc put(self: var Pod, typeof: typedesc[Var], flags: varargs[int]) =
  self = pxd.pods.initPod(cast[pointer](Var()), flags)


proc put*[T](api; key: string, val: T, flags: varargs[int]): ptr T {.discardable.} =
  let pod = varsPod[key].addr; put(pod[], val, flags)
  result = pod[].valPtr(T)


proc put*(api; key: string, val: Var, flags: varargs[int]): Var =
  let pod = varsPod[key].addr
  pod[]  = pxd.pods.initPod(cast[pointer](val), flags)
  result = val


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
varsPod = pxd.pods.initPodObject()


proc source*(api;): var Pod {.inline.}=
  varsPod


proc newVar*[T](api; arg: T): Var =
  result = Var()
  result.wrap(arg)


proc setFlags*(api; key: string, flags: varargs[int]) =
  m_pods.setFlags(varsPod[key], flags)
