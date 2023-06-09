import pxd/m_pods

const VARS_DONT_SAVE* = POD_DONT_SAVE
type Var* = ref object
  val*: pointer