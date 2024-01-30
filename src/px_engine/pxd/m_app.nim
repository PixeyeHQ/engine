import ../px_engine_types


type 
  App* = ref object of Obj


method onWindowResize*(self: App) {.base.} = discard