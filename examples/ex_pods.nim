#[
  POD (Pack of Data) is the engine Intermediate Data Format like JSON
]#
import std/strutils
import engine
import engine/pxd/pods/pods # you need to import this in order to make custom pod hooks. #todo: this must be done another way I think.

type UnitKind = enum
  Melee = "Melee",
  Range = "Range",
  Mage  = "Mage"

type UnitObj = object
  name:  string
  pos:   Vec3
  power: int
  cost:  int
  kind:  UnitKind


proc toPodHook*[T: UnitKind](pod: var Pod, obj: T) =
  toPodHook(pod, $obj)


proc fromPodHook*(pod: var Pod, result: var UnitKind) =
  result = parseEnum[UnitKind](pod.vstring)

pxd.run():
  var unit1 = UnitObj(name: "Katbert", pos: vec(10,10,0), power: 100, cost: 10, kind: Range)
  var unit2 = UnitObj(name: "Alan", pos: vec(5,10,0), power: 90, cost: 10, kind: Mage)
  var unit3 = UnitObj(name: "Roland", pos: vec(12,10,5), power: 150, cost: 20, kind: Melee)
  var pod   = pxd.pods.initPodObject()
  pod["Katbert"] = pxd.pods.toPod(unit1)
  pod["Alan"]    = pxd.pods.toPod(unit2)
  pod["Roland"]  = pxd.pods.toPod(unit3)
  # io.path("*/") returns path to persistent app data.
  # windows: %userprofile%\AppData\Roaming\<companyname>\<productname>
  # default <companyname> is 'Unknown' and default <productname> is 'New Game'
  # those settings can be changed in engine.pod file.
  pxd.pods.toPodFile(io.path("*/dense.pod"),   pod, PodSettings(style: PodStyle.Dense))
  pxd.pods.toPodFile(io.path("*/compact.pod"), pod, PodSettings(style: PodStyle.Compact))
  pxd.pods.toPodFile(io.path("*/sparse.pod"),  pod, PodSettings(style: PodStyle.Sparse))
  # Compact: save pod to file without spaces in one line.
  # Dense:   save pod to file in a verbose tree format. Usually used for configs.
  # Sparse:  save pod to file in a json like tree format. Sparse also enables pretty formatting for variables. In future this will be optional.
  var pod_loaded   = pxd.pods.fromPodFile(io.path("*/dense.pod"))
  var unit1_loaded = pxd.pods.fromPod(pod_loaded["Katbert"], UnitObj)
  var unit2_loaded = pxd.pods.fromPod(pod_loaded["Alan"], UnitObj)
  var unit3_loaded = pxd.pods.fromPod(pod_loaded["Roland"], UnitObj)

  print unit1_loaded
  print unit2_loaded
  print unit3_loaded