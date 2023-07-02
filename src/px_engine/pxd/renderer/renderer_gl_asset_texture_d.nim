import px_engine/pxd/definition/api


type 
  TextureObject* = object
    id*:     u32
    width*:  i32
    height*: i32
  Texture* = distinct u32
  Texture2D_Object* = object
    id*:     u32
    width*:  i32
    height*: i32
  Texture2D* = distinct Handle


