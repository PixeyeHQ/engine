{.warning[ImplicitDefaultValue]:off.}

import std/math,random
import math_d

when defined(v32):
    type float = float32

type VecAny  = Vec | Vec3 | Vec2
type Vec4or3 = Vec | Vec3

proc vec*(x,y,z,w: int): Vec {.inline.} =
    return (x.float,y.float,z.float,w.float)

proc vec*(x,y,z,w: float): Vec {.inline.} =
    return (x,y,z,w)

proc vec*(x,y,z: float): Vec3 {.inline.} =
    return (x,y,z)

proc vec*(x,y: float): Vec2 {.inline.} =
    return (x,y)

const #identity
    vec2_default* = vec(0,0)
    vec_zero*     = vec(0,0,0,0)
    vec_one*      = vec(1,1,1,1)
    vec_right*    = vec(1,0,0,0)
    vec_left*     = vec(-1,0,0,0)
    vec_up*       = vec(0,1,0,0)
    vec_down*     = vec(0,-1,0,0)
    vec_forward*  = vec(0,0,1,0)
    vec_backward* = vec(0,0,-1,0)
    center*       = vec(0.5,0.5)
    bottom_left*  = vec(0,0)
    
proc xy*(this: var VecAny, x,y: float) = this.x = x; this.y = y
proc xy*(this: var VecAny): Vec2                   = (this.x,this.y)
proc xyz*(this: var Vec4or3): Vec3                  = result = (this.x,this.y,this.z)
proc xyz*(this: var Vec): Vec3                  = result = (this.x,this.y,this.z)
proc xyz*(this: Vec): Vec3                  = result = (this.x,this.y,this.z)
proc vec2*(x,y:     float = 0):   Vec2 {.inline.} = (x,y)
proc vec3*(x,y,z:   float = 0):   Vec3 {.inline.} = (x,y,z)
proc col*(r,g,b,a:  float = 1):   Vec {.inline.}  = (r,g,b,a)
proc rgb*(r,g,b,a:  float = 255): Vec {.inline.}  = (r/255f,g/255f,b/255f,a/255f)
proc rgba*(r,g,b,a: float = 0):   Vec {.inline.}  = (r,g,b,a)

const cWhite*  = rgba(1,1,1,1)
const cRed*    = rgba(1,0,0,1)
const cGreen*  = rgba(0,1,0,1)
const cBlue*   = rgba(0,0,1,1)
const cYellow* = rgba(1,1,0,1)

proc r*(this: var VecAny): float  = this.x
proc g*(this: var VecAny): float  = this.y
proc b*(this: var Vec4or3): float = this.z
proc a*(this: var Vec): float     = this.w

proc w*(this: var VecAny): float = this.x
proc h*(this: var VecAny): float = this.y

proc u*(this: var VecAny): float = this.x
proc `u=`*(this: var VecAny, arg: float) = this.x = arg
proc v*(this: var VecAny): float = this.y
proc `v=`*(this: var VecAny, arg: float) = this.y = arg

proc r*(this: VecAny): float  = this.x
proc g*(this: VecAny): float  = this.y
proc b*(this: Vec4or3): float = this.z
proc a*(this: Vec): float     = this.w

proc w*(this: VecAny): float = this.x
proc h*(this: VecAny): float = this.y

proc u*(this: VecAny): float = this.x
proc v*(this: VecAny): float = this.y

proc `==`*(a,b:var Vec): bool =
    a.x == b.x and
    a.y == b.y and
    a.z == b.z and
    a.w == b.w


proc `+`*(a: Vec, b: Vec): Vec {.inline.} =
    (a.x+b.x, a.y+b.y, a.z+b.z, a.w+b.w)


proc `+`*(a: Vec2, b: Vec2): Vec2 {.inline.} =
    (a.x+b.x, a.y+b.y)


proc `-`*(a: Vec, b: Vec): Vec {.inline.} =
    (a.x-b.x, a.y-b.y, a.z-b.z, a.w-b.w)


proc `-`*(a: Vec3, b: Vec3): Vec3 {.inline.} =
    (a.x-b.x, a.y-b.y, a.z-b.z)


proc `-`*(a: Vec2, b: Vec2): Vec2 {.inline.} =
    (a.x-b.x, a.y-b.y)


proc `-`*(a: Vec, b: SomeNumber): Vec2 {.inline.} =
    vec2(a.x-b, a.y-b)


proc `*`*(a: Vec, b: SomeNumber): Vec {.inline.} =
    vec(a.x*b.float, a.y*b.float, a.z*b.float, a.w*b.float)


proc `*`*(a: Vec3, b: SomeNumber): Vec3 {.inline.} =
    vec3(a.x*b.float, a.y*b.float, a.z*b.float)


proc `*`*(a: Vec3, b: Vec3): Vec3 {.inline.} =
    vec3(a.x*b.x, a.y*b.y, a.z*b.z)


proc `*`*(a: Vec2, b: SomeNumber): Vec2 {.inline.} =
    vec2(a.x*b.float, a.y*b.float)


proc `/`*(a: Vec2, b: SomeNumber): Vec2 {.inline.} =
    vec2(a.x/b.float, a.y/b.float)


proc `*`*(b: SomeNumber, a: Vec): Vec {.inline.} =
    vec(a.x*b.float, a.y*b.float, a.z*b.float, a.w*b.float)


proc `+=`*(self: var Vec, other: Vec) =
    self.x = self.x+other.x
    self.y = self.y+other.y
    self.z = self.z+other.z
    self.w = self.w+other.w


proc `+=`*(self: var Vec2, other: Vec2) =
    self.x = self.x+other.x
    self.y = self.y+other.y


proc `-=`*(self: var Vec, other: Vec) =
    self.x = self.x-other.x
    self.y = self.y-other.y
    self.z = self.z-other.z
    self.w = self.w-other.w


proc `*=`*(self: var Vec, other: Vec) =
    self.x = self.x*other.x
    self.y = self.y*other.y
    self.z = self.z*other.z
    self.w = self.w*other.w


proc `*=`*(self: var Vec, other: float = 1) =
    self.x = self.x*other
    self.y = self.y*other
    self.z = self.z*other
    self.w = self.w*other

proc `*=`*(self: var Vec3, other: float = 1) =
    self.x = self.x*other
    self.y = self.y*other
    self.z = self.z*other


proc `*=`*(self: var Vec2, other: float = 1) =
    self.x = self.x*other
    self.y = self.y*other


proc `/=` *(self: var Vec, other: Vec) =
    self.x = self.x/other.x
    self.y = self.y/other.y
    self.z = self.z/other.z
    self.w = self.w/other.w


proc `/=` *(self: var Vec, other: float = 1) =
    self.x = self.x/other
    self.y = self.y/other
    self.z = self.z/other
    self.w = self.w/other


proc `/=` *(self: var Vec3, other: float = 1) =
    self.x = self.x/other
    self.y = self.y/other
    self.z = self.z/other


proc distanceSquared*(a, b: Vec2): float =
  let dx = b.x - a.x
  let dy = b.y - a.y
  return dx * dx + dy * dy


proc sqrMagnitude*(vec: Vec): float {.inline.} =
    vec.x * vec.x + vec.y * vec.y + vec.z * vec.z


proc magnitude*(vec: Vec): float {.inline.} =
    sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)


proc magnitude*(vec: Vec3): float {.inline.} =
    sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)


proc getNormal*(edge: Vec2): Vec2 {.inline.} =
    vec2(-edge.y, edge.x)


proc normalize*(self: var Vec) =
    var arg = self.magnitude

    if arg != 0:
        arg = 1.0/arg
    self.x *= arg
    self.y *= arg
    self.z *= arg


proc normalized*(vec: Vec): Vec =
    var v = vec
    normalize(v)
    return v


proc normalize*(self: var Vec3) =
    var arg = self.magnitude

    if arg != 0:
        arg = 1.0/arg
    self.x *= arg
    self.y *= arg
    self.z *= arg


proc normalized*(vec: Vec3): Vec3 =
    var v = vec
    normalize(v)
    return v


proc atan2*(y,x: float): float {.inline.} =
  return math.arctan2(y,x)


proc cross*(vec1, vec2: Vec): Vec {.inline.} =
    vec(
        #x 
        vec1.y * vec2.z - vec1.z * vec2.y,
        #y 
        vec1.z * vec2.x - vec1.x * vec2.z,
        #z
        vec1.x * vec2.y - vec1.y * vec2.x,
        #w
        0)


proc cross2*(a, b, c: Vec2): float =
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)


proc dot2*(vec1, vec2: Vec): float {.inline.} =
    vec1.x * vec2.x + vec1.y * vec2.y


proc dot*(vec1, vec2: Vec): float {.inline.} =
    vec1.x * vec2.x + vec1.y * vec2.y + vec1.z * vec2.z


proc dot4*(vec1, vec2: Vec): float {.inline.} =
    vec1.x * vec2.x + vec1.y * vec2.y + vec1.z * vec2.z + vec1.w * vec2.w


proc rand*(self: var Vec, arg: float) =
    self.x = rand(-arg..arg)
    self.y = rand(-arg..arg)
    self.z = rand(-arg..arg)


proc rand*(self: var Vec, arg1,arg2,arg3: float) =
    self.x = rand(-arg1..arg1)
    self.y = rand(-arg2..arg2)
    self.z = rand(-arg3..arg3)


template vecr*(x,y,z,ox,oy,cos,sin: float): Vec3 =
  vec((x - ox) * cos - (y - oy) * -sin + ox, 
      (x - ox) * -sin + (y - oy) * cos + oy, z)


converter to_vec*(v: Vec2): Vec {.inline.} = (v.x,v.y,0.float,0.float)
converter to_vec*(v: Vec3): Vec {.inline.} = (v.x,v.y,v.z,0.float)
converter to_vec2*(v: Vec3): Vec2 {.inline.} = (v.x,v.y)
converter to_vec3*(v: Vec2): Vec3 {.inline.} = (v.x,v.y,0.float)


#-----------------------------------------------------------------------------------------------------------------------
#@bivectors
#-----------------------------------------------------------------------------------------------------------------------
proc bvec3*(x,y,z: float32): BVec3 =
    result.b01 = x
    result.b02 = y
    result.b12 = z


proc wedge*(a,b: Vec3): BVec3 =
    ## The outher product of two vectors to form a plane.
    result = (
        a.x*b.y - a.y*b.x, # XY
        a.x*b.z - a.z*b.x, # XZ
        a.y*b.z - a.z*b.y  # YZ
    )

template `^`*(a,b: Vec3): BVec3 =
    ## The outher product of two vectors to form a plane.
    wedge(a,b)