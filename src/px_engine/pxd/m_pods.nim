import px_engine/pxd/definition/api
import pods/pods as m_pods
import pods/pods_d
export pods_d
export m_pods.add
export m_pods.setFlags
export m_pods.`[]`
export m_pods.`[]=`
export m_pods.valPtr
export m_pods.val
export m_pods.fromPod
export m_pods.PodDigits


#---------------------------------------------------------------------------------------------
# @api pod object constructors
#---------------------------------------------------------------------------------------------
using api: PodsAPI
proc initPod*(api; arg: int, flags: varargs[int]): Pod =
  initPod(arg, flags)


proc initPod*(api; arg: float, flags: varargs[int]): Pod =
  initPod(arg, flags)


proc initPod*(api; arg: string, flags: varargs[int]): Pod =
  initPod(arg, flags)


proc initPod*(api; arg: bool, flags: varargs[int]): Pod =
  initPod(arg, flags)


proc initPod*(api; arg: pointer, flags: varargs[int]): Pod =
  initPod(arg, flags)


proc initPodArray*(api; flags: varargs[int]): Pod =
  initPodArray(flags)


proc initPodObject*(api; flags: varargs[int]): Pod =
  initPodObject(flags)


proc fromPodFile*(api; filePath: string): Pod =
  m_pods.fromPodFile(filePath)


proc fromPod*[T: not Pod](api; pod: var Pod, typeof: typedesc[T]): typeof =
  m_pods.fromPod(pod,typeof)


proc fromPod*[T: not Pod](api; pod: Pod, typeof: typedesc[T]): typeof =
  m_pods.fromPod(pod,typeof)


proc fromPodString*[T: not Pod](api; podsource: string, typeof: typedesc[T]): typeof =
  m_pods.fromPodString(podsource, typeof)


proc fromPodFile*(api; filePath: string, pod: var Pod) =
  var next = m_pods.fromPodFile(filePath)
  pod.merge(next)


proc fromPodFile*[T: not Pod](api; filePath: string, typeof: typedesc[T]): typeof =
  var pod = m_pods.fromPodFile(filePath)
  m_pods.fromPod(pod, typeof)


proc toPodFile*(api; path: string, pod: Pod, podSettings: PodSettings = podConfigDefault) =
  m_pods.toPodFile(path, pod, podSettings)


proc toPodString*[T: not (Pod)](api; obj: var T): string =
  m_pods.toPodString(obj)


proc toPod*[T](api; obj: T): Pod =
  m_pods.toPod(obj)