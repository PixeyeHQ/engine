import std/math

when defined(v32):
  type float = float32

type BVec3*     = tuple[b01,b02,b12: float]
type Vec*       = tuple[x,y,z,w: float]
type Vec3*      = tuple[x,y,z  : float]
type Vec2*      = tuple[x,y    : float]
type Color*     = Vec
type Matrix*    = tuple[e11,e12,e13,e14,e21,e22,e23,e24,e31,e32,e33,e34,e41,e42,e43,e44: float32]
type Matrix3x3* = tuple[e11,e12,e13,e21,e22,e23,e31,e32,e33: float32]
type Matrix3x2* = tuple[e11,e12,e21,e22,e31,e32: float32]
type Rotor3*    = tuple[a: float,b01,b02,b12: float]
type Quat*      = tuple[w: float,x,y,z: float]

type rad*     = distinct float


const rad_per_deg*  = PI / 180.0 
const RAD2DEG*      = 180.0 / PI
const DEG2RAD*      = PI / 180.0 
const epsilon_sqrt* = 1e-15F
const epsilon*      = 0.00001 #for floating-point inaccuracies.


proc radians*(angle: float): float {.inline.} = angle * rad_per_deg


proc rads*(angle: float): rad {.inline.} = (angle * rad_per_deg).rad


proc max*(val1: float, val2: float): float =
    if val1 < val2: val2 else: val1