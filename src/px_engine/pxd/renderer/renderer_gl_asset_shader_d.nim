import px_engine/pxd/definition/api


type 
  ShaderError* = enum
    RE_SHADER_NO_VERT_FILE,
    RE_SHADER_NO_FRAG_FILE

  ShaderObject* = object
    program*: uint32

  Shader* = distinct Handle