{.warning[ImplicitDefaultValue]:off.}

import std/math
import math_d
import math_vector

when defined(v32):
    type float = float32


proc identity*(mx: var Matrix) =
    mx.e11 = 1; mx.e12 = 0; mx.e13 = 0; mx.e14 = 0;
    mx.e21 = 0; mx.e22 = 1; mx.e23 = 0; mx.e24 = 0;
    mx.e31 = 0; mx.e32 = 0; mx.e33 = 1; mx.e34 = 0;
    mx.e41 = 0; mx.e42 = 0; mx.e43 = 0; mx.e44 = 1


proc matrixIdentity*(): Matrix =
    var mx: Matrix
    mx.e11 = 1; mx.e12 = 0; mx.e13 = 0; mx.e14 = 0;
    mx.e21 = 0; mx.e22 = 1; mx.e23 = 0; mx.e24 = 0;
    mx.e31 = 0; mx.e32 = 0; mx.e33 = 1; mx.e34 = 0;
    mx.e41 = 0; mx.e42 = 0; mx.e43 = 0; mx.e44 = 1
    result = mx


proc matrix*(): Matrix = result.identity()


proc matrix3*(a,b,c: Vec3): Matrix3x3 =
    result.e11 = a.x; result.e12 = b.x; result.e13 = c.x;
    result.e21 = a.y; result.e22 = b.y; result.e23 = c.y;
    result.e31 = a.z; result.e32 = b.z; result.e33 = c.z;


proc matrix3*(): Matrix3x3 =
    result.e11 = 1; result.e12 = 0; result.e13 = 0;
    result.e21 = 0; result.e22 = 1; result.e23 = 0;
    result.e31 = 0; result.e32 = 0; result.e33 = 1;



proc normalize*(x,y,z : var float) =
    let d = sqrt(x*x + y*y + z*z)
    x /= d; y /= d; z /= d


proc initTranslation*(mx: var Matrix, x,y,z : float) =
    mx.e11 = 1.0; mx.e12 = 0.0; mx.e13 =  0.0; mx.e14 = 0.0;
    mx.e21 = 0.0; mx.e22 = 1.0; mx.e23 =  0.0; mx.e24 = 0.0;
    mx.e31 = 0.0; mx.e32 = 0.0; mx.e33 =  1.0; mx.e34 = 0.0;
    mx.e41 =   x; mx.e42 =   y; mx.e43 =    z; mx.e44 = 1.0


proc initScale*(mx: var Matrix; x,y,z: float) = 
    mx.e11 =   x; mx.e12 = 0.0; mx.e13 =  0.0; mx.e14 = 0.0;
    mx.e21 = 0.0; mx.e22 =   y; mx.e23 =  0.0; mx.e24 = 0.0;
    mx.e31 = 0.0; mx.e32 = 0.0; mx.e33 =    z; mx.e34 = 0.0;
    mx.e41 = 0.0; mx.e42 = 0.0; mx.e43 =  0.0; mx.e44 = 1.0


proc initRotation*(mx: var Matrix; x,y,z: float) =
    let cx = cos(x)
    let sx = sin(x)
    let cy = cos(y)
    let sy = sin(y)
    let cz = cos(z)
    let sz = sin(z)
    let cxsy = cx * sy
    let sxsy = sx * sy

    mx.e11 = cy * cz
    mx.e12 = cy * sz
    mx.e13 =  -sy
    mx.e14 = 0.0

    mx.e21 = sxsy * cz - cx * sz
    mx.e22 = sxsy * sz + cx * cz
    mx.e23 = sx * cy
    mx.e24 = 0.0

    mx.e31 = cxsy * cz + sx * sz
    mx.e32 = cxsy * sz - sx * cz
    mx.e33 = cx * cy
    mx.e34 = 0.0

    mx.e41 = 0.0
    mx.e42 = 0.0 
    mx.e43 = 0.0 
    mx.e44 = 1.0


proc initRotation*(mx: var Matrix, x,y,z: float, angle: float) =
    var x = x
    var y = y
    var z = z
    normalize(x,y,z)
    var s = sin(angle)
    var c = cos(angle)
    var vs = 1 - c # versine

    mx.e11 = vs * x * x + c
    mx.e12 = vs * x * y - z * s
    mx.e13 = vs * z * x + y * s
    mx.e14 = 0

    mx.e21 = vs * x * y + z * s
    mx.e22 = vs * y * y + c
    mx.e23 = vs * y * z - x * s
    mx.e24 = 0

    mx.e31 = vs * z * x - y * s
    mx.e32 = vs * y * z + x * s
    mx.e33 = vs * z * z + c
    mx.e34 = 0
    
    mx.e41 = 0
    mx.e42 = 0
    mx.e43 = 0
    mx.e44 = 1


proc initRotation*(mx: var Matrix3x3,  x,y,z: float, angle: float) =
    var x = x
    var y = y
    var z = z
    normalize(x,y,z)
    var rangle = angle.radians
    let s  = sin(rangle)
    let c  = cos(rangle)
    let vs = 1 - c # versine
    let vsx = vs * x
    let vsy = vs * y
    let vsz = vs * z
    let zs  = z * s
    let ys  = y * s
    let xs  = x * s

    mx.e11 = vsx * x + c
    mx.e12 = vsx * y - zs
    mx.e13 = vsz * x + ys

    mx.e21 = vsx * y + zs
    mx.e22 = vsy * y + c
    mx.e23 = vsy * z - xs
    
    mx.e31 = vsz * x - ys
    mx.e32 = vsy * z + xs
    mx.e33 = vsz * z + c


proc initRotation2d*(mx: var Matrix3x2, x,y,z: float, angle: float) =
    var x = x
    var y = y
    var z = z
    normalize(x,y,z)
    var rangle = angle.radians
    let s  = sin(rangle)
    let c  = cos(rangle)
    let vs = 1 - c # versine
    let vsx = vs * x
    let vsy = vs * y
    let vsz = vs * z
    let xs  = x * s
    let ys  = y * s
    let zs  = z * s

    mx.e11 = vsx * x + c
    mx.e12 = vsx * y - zs

    mx.e21 = vsx * y + zs
    mx.e22 = vsy * y + c
    
    mx.e31 = vsz * x - ys
    mx.e32 = vsy * z + xs


proc initRotation*(mx: var Matrix3x3, axis: Vec3, angle: float) {.inline.} =
    initrotation(mx,axis.x,axis.y,axis.z,angle)


proc initRotation2d*(mx: var Matrix3x2, axis: Vec3, angle: float) {.inline.} =
    initrotation2d(mx,axis.x,axis.y,axis.z,angle)


proc initRotationx*(mx: var Matrix, a: float) =
    let cos = cos(a)
    let sin = sin(a)
    mx.e11 = 1.0; mx.e12 = 0.0; mx.e13 =  0.0; mx.e14 = 0.0;
    mx.e21 = 0.0; mx.e22 = cos; mx.e23 = -sin; mx.e24 = 0.0;
    mx.e31 = 0.0; mx.e32 = sin; mx.e33 =  cos; mx.e34 = 0.0;
    mx.e41 = 0.0; mx.e42 = 0.0; mx.e43 =  0.0; mx.e44 = 1.0


proc initRotationy*(mx: var Matrix, a: float) =
    let cos = cos(a)
    let sin = sin(a)
    mx.e11 =  cos; mx.e12 = 0.0; mx.e13 = sin; mx.e14 = 0.0;
    mx.e21 =  0.0; mx.e22 = 1.0; mx.e23 = 0.0; mx.e24 = 0.0;
    mx.e31 = -sin; mx.e32 = 0.0; mx.e33 = cos; mx.e34 = 0.0;
    mx.e41 =  0.0; mx.e42 = 0.0; mx.e43 = 0.0; mx.e44 = 1.0


proc initRotationz*(mx: var Matrix, a: float) =
    let cos = cos(a)
    let sin = sin(a)
    mx.e11 = cos; mx.e12 = -sin; mx.e13 = 0.0; mx.e14 = 0.0;
    mx.e21 = sin; mx.e22 =  cos; mx.e23 = 0.0; mx.e24 = 0.0;
    mx.e31 = 0.0; mx.e32 =  0.0; mx.e33 = 1.0; mx.e34 = 0.0;
    mx.e41 = 0.0; mx.e42 =  0.0; mx.e43 = 0.0; mx.e44 = 1.0


proc matrix*(x,y,z: float): Matrix = result.init_scale(x,y,z)


proc `==`*(mx1: var Matrix, mx2: var Matrix): bool =
    mx1.e11 == mx2.e11 and
    mx1.e12 == mx2.e12 and
    mx1.e13 == mx2.e13 and
    mx1.e14 == mx2.e14 and
    mx1.e21 == mx2.e21 and
    mx1.e22 == mx2.e22 and
    mx1.e23 == mx2.e23 and
    mx1.e24 == mx2.e24 and
    mx1.e31 == mx2.e41 and
    mx1.e32 == mx2.e42 and
    mx1.e33 == mx2.e43 and
    mx1.e34 == mx2.e44 and
    mx1.e41 == mx2.e41 and
    mx1.e42 == mx2.e42 and
    mx1.e43 == mx2.e43 and
    mx1.e44 == mx2.e44


proc `!=`*(mx1: var Matrix, mx2: var Matrix): bool =
    mx1.e11 != mx2.e11 or
    mx1.e12 != mx2.e12 or
    mx1.e13 != mx2.e13 or
    mx1.e14 != mx2.e14 or
    mx1.e21 != mx2.e21 or
    mx1.e22 != mx2.e22 or
    mx1.e23 != mx2.e23 or
    mx1.e24 != mx2.e24 or
    mx1.e31 != mx2.e41 or
    mx1.e32 != mx2.e42 or
    mx1.e33 != mx2.e43 or
    mx1.e34 != mx2.e44 or
    mx1.e41 != mx2.e41 or
    mx1.e42 != mx2.e42 or
    mx1.e43 != mx2.e43 or
    mx1.e44 != mx2.e44


proc equals*(mx1: var Matrix, mx2: var Matrix): bool {.inline.} = mx1 == mx2


proc `*`*(mx: var Matrix, v: float) =
    mx.e11 *= v
    mx.e12 *= v
    mx.e13 *= v
    mx.e14 *= v

    mx.e21 *= v
    mx.e22 *= v
    mx.e23 *= v
    mx.e24 *= v

    mx.e31 *= v
    mx.e32 *= v
    mx.e33 *= v
    mx.e34 *= v

    mx.e41 *= v
    mx.e42 *= v
    mx.e43 *= v
    mx.e44 *= v


proc `*`*(mx: var Matrix, v: float): Matrix =
    result.e11 = mx.e11 * v
    result.e12 = mx.e12 * v
    result.e13 = mx.e13 * v
    result.e14 = mx.e14 * v

    result.e21 = mx.e21 * v
    result.e22 = mx.e22 * v
    result.e23 = mx.e23 * v
    result.e24 = mx.e24 * v

    result.e31 = mx.e31 * v
    result.e32 = mx.e32 * v
    result.e33 = mx.e33 * v
    result.e34 = mx.e34 * v

    result.e41 = mx.e41 * v
    result.e42 = mx.e42 * v
    result.e43 = mx.e43 * v
    result.e44 = mx.e44 * v


proc mul*(v: Vec, mx: Matrix): Vec3 =
    result.x = mx.e11*v.x + mx.e21 * v.y + mx.e31 * v.z + mx.e41
    result.y = mx.e12*v.x + mx.e22 * v.y + mx.e32 * v.z + mx.e42
    result.z = mx.e13*v.x + mx.e23 * v.y + mx.e33 * v.z + mx.e43


proc mul*(mx: Matrix, v: Vec): Vec3 =
    result.x = mx.e11 * v.x + mx.e21 * v.y + mx.e31 * v.z + mx.e41
    result.y = mx.e12 * v.x + mx.e22 * v.y + mx.e32 * v.z + mx.e42
    result.z = mx.e13 * v.x + mx.e23 * v.y + mx.e33 * v.z + mx.e43

proc `*`*(v: Vec, mx: Matrix): Vec3 =
    result.x = mx.e11 * v.x + mx.e21 * v.y + mx.e31 * v.z + mx.e41
    result.y = mx.e12 * v.x + mx.e22 * v.y + mx.e32 * v.z + mx.e42
    result.z = mx.e13 * v.x + mx.e23 * v.y + mx.e33 * v.z + mx.e43


proc `*`*(mx: Matrix, v: Vec): Vec3 =
    result.x = mx.e11 * v.x + mx.e21 * v.y + mx.e31 * v.z + mx.e41
    result.y = mx.e12 * v.x + mx.e22 * v.y + mx.e32 * v.z + mx.e42
    result.z = mx.e13 * v.x + mx.e23 * v.y + mx.e33 * v.z + mx.e43


proc `*`*(mx: var Matrix, v: Vec): Vec =
    result.x = mx.e11 * v.x + mx.e12 * v.y + mx.e13 * v.z + mx.e14 * v.w
    result.y = mx.e21 * v.x + mx.e22 * v.y + mx.e23 * v.z + mx.e24 * v.w
    result.z = mx.e31 * v.x + mx.e32 * v.y + mx.e33 * v.z + mx.e34 * v.w
    result.w = mx.e41 * v.x + mx.e42 * v.y + mx.e43 * v.z + mx.e44 * v.w


# todo: inline math ops
proc multiply*(b:  Matrix, a:  Matrix): Matrix =
    result.e11 = a.e11 * b.e11 + a.e12 * b.e21 + a.e13 * b.e31 + a.e14 * b.e41
    result.e12 = a.e11 * b.e12 + a.e12 * b.e22 + a.e13 * b.e32 + a.e14 * b.e42
    result.e13 = a.e11 * b.e13 + a.e12 * b.e23 + a.e13 * b.e33 + a.e14 * b.e43
    result.e14 = a.e11 * b.e14 + a.e12 * b.e24 + a.e13 * b.e34 + a.e14 * b.e44

    result.e21 = a.e21 * b.e11 + a.e22 * b.e21 + a.e23 * b.e31 + a.e24 * b.e41
    result.e22 = a.e21 * b.e12 + a.e22 * b.e22 + a.e23 * b.e32 + a.e24 * b.e42
    result.e23 = a.e21 * b.e13 + a.e22 * b.e23 + a.e23 * b.e33 + a.e24 * b.e43
    result.e24 = a.e21 * b.e14 + a.e22 * b.e24 + a.e23 * b.e34 + a.e24 * b.e44

    result.e31 = a.e31 * b.e11 + a.e32 * b.e21 + a.e33 * b.e31 + a.e34 * b.e41
    result.e32 = a.e31 * b.e12 + a.e32 * b.e22 + a.e33 * b.e32 + a.e34 * b.e42
    result.e33 = a.e31 * b.e13 + a.e32 * b.e23 + a.e33 * b.e33 + a.e34 * b.e43
    result.e34 = a.e31 * b.e14 + a.e32 * b.e24 + a.e33 * b.e34 + a.e34 * b.e44

    result.e41 = a.e41 * b.e11 + a.e42 * b.e21 + a.e43 * b.e31 + a.e44 * b.e41
    result.e42 = a.e41 * b.e12 + a.e42 * b.e22 + a.e43 * b.e32 + a.e44 * b.e42
    result.e43 = a.e41 * b.e13 + a.e42 * b.e23 + a.e43 * b.e33 + a.e44 * b.e43
    result.e44 = a.e41 * b.e14 + a.e42 * b.e24 + a.e43 * b.e34 + a.e44 * b.e44


proc `*`*(b: Matrix, a: Matrix): Matrix =
    result.e11 = a.e11 * b.e11 + a.e12 * b.e21 + a.e13 * b.e31 + a.e14 * b.e41
    result.e12 = a.e11 * b.e12 + a.e12 * b.e22 + a.e13 * b.e32 + a.e14 * b.e42
    result.e13 = a.e11 * b.e13 + a.e12 * b.e23 + a.e13 * b.e33 + a.e14 * b.e43
    result.e14 = a.e11 * b.e14 + a.e12 * b.e24 + a.e13 * b.e34 + a.e14 * b.e44

    result.e21 = a.e21 * b.e11 + a.e22 * b.e21 + a.e23 * b.e31 + a.e24 * b.e41
    result.e22 = a.e21 * b.e12 + a.e22 * b.e22 + a.e23 * b.e32 + a.e24 * b.e42
    result.e23 = a.e21 * b.e13 + a.e22 * b.e23 + a.e23 * b.e33 + a.e24 * b.e43
    result.e24 = a.e21 * b.e14 + a.e22 * b.e24 + a.e23 * b.e34 + a.e24 * b.e44

    result.e31 = a.e31 * b.e11 + a.e32 * b.e21 + a.e33 * b.e31 + a.e34 * b.e41
    result.e32 = a.e31 * b.e12 + a.e32 * b.e22 + a.e33 * b.e32 + a.e34 * b.e42
    result.e33 = a.e31 * b.e13 + a.e32 * b.e23 + a.e33 * b.e33 + a.e34 * b.e43
    result.e34 = a.e31 * b.e14 + a.e32 * b.e24 + a.e33 * b.e34 + a.e34 * b.e44

    result.e41 = a.e41 * b.e11 + a.e42 * b.e21 + a.e43 * b.e31 + a.e44 * b.e41
    result.e42 = a.e41 * b.e12 + a.e42 * b.e22 + a.e43 * b.e32 + a.e44 * b.e42
    result.e43 = a.e41 * b.e13 + a.e42 * b.e23 + a.e43 * b.e33 + a.e44 * b.e43
    result.e44 = a.e41 * b.e14 + a.e42 * b.e24 + a.e43 * b.e34 + a.e44 * b.e44


proc `*`*(b: var Matrix, a: var Matrix): Matrix =
    result.e11 = a.e11 * b.e11 + a.e12 * b.e21 + a.e13 * b.e31 + a.e14 * b.e41
    result.e12 = a.e11 * b.e12 + a.e12 * b.e22 + a.e13 * b.e32 + a.e14 * b.e42
    result.e13 = a.e11 * b.e13 + a.e12 * b.e23 + a.e13 * b.e33 + a.e14 * b.e43
    result.e14 = a.e11 * b.e14 + a.e12 * b.e24 + a.e13 * b.e34 + a.e14 * b.e44

    result.e21 = a.e21 * b.e11 + a.e22 * b.e21 + a.e23 * b.e31 + a.e24 * b.e41
    result.e22 = a.e21 * b.e12 + a.e22 * b.e22 + a.e23 * b.e32 + a.e24 * b.e42
    result.e23 = a.e21 * b.e13 + a.e22 * b.e23 + a.e23 * b.e33 + a.e24 * b.e43
    result.e24 = a.e21 * b.e14 + a.e22 * b.e24 + a.e23 * b.e34 + a.e24 * b.e44

    result.e31 = a.e31 * b.e11 + a.e32 * b.e21 + a.e33 * b.e31 + a.e34 * b.e41
    result.e32 = a.e31 * b.e12 + a.e32 * b.e22 + a.e33 * b.e32 + a.e34 * b.e42
    result.e33 = a.e31 * b.e13 + a.e32 * b.e23 + a.e33 * b.e33 + a.e34 * b.e43
    result.e34 = a.e31 * b.e14 + a.e32 * b.e24 + a.e33 * b.e34 + a.e34 * b.e44

    result.e41 = a.e41 * b.e11 + a.e42 * b.e21 + a.e43 * b.e31 + a.e44 * b.e41
    result.e42 = a.e41 * b.e12 + a.e42 * b.e22 + a.e43 * b.e32 + a.e44 * b.e42
    result.e43 = a.e41 * b.e13 + a.e42 * b.e23 + a.e43 * b.e33 + a.e44 * b.e43
    result.e44 = a.e41 * b.e14 + a.e42 * b.e24 + a.e43 * b.e34 + a.e44 * b.e44


proc mul*(a: Matrix, b: Matrix): Matrix =
    result.e11 = a.e11 * b.e11 + a.e12 * b.e21 + a.e13 * b.e31 + a.e14 * b.e41
    result.e12 = a.e11 * b.e12 + a.e12 * b.e22 + a.e13 * b.e32 + a.e14 * b.e42
    result.e13 = a.e11 * b.e13 + a.e12 * b.e23 + a.e13 * b.e33 + a.e14 * b.e43
    result.e14 = a.e11 * b.e14 + a.e12 * b.e24 + a.e13 * b.e34 + a.e14 * b.e44

    result.e21 = a.e21 * b.e11 + a.e22 * b.e21 + a.e23 * b.e31 + a.e24 * b.e41
    result.e22 = a.e21 * b.e12 + a.e22 * b.e22 + a.e23 * b.e32 + a.e24 * b.e42
    result.e23 = a.e21 * b.e13 + a.e22 * b.e23 + a.e23 * b.e33 + a.e24 * b.e43
    result.e24 = a.e21 * b.e14 + a.e22 * b.e24 + a.e23 * b.e34 + a.e24 * b.e44

    result.e31 = a.e31 * b.e11 + a.e32 * b.e21 + a.e33 * b.e31 + a.e34 * b.e41
    result.e32 = a.e31 * b.e12 + a.e32 * b.e22 + a.e33 * b.e32 + a.e34 * b.e42
    result.e33 = a.e31 * b.e13 + a.e32 * b.e23 + a.e33 * b.e33 + a.e34 * b.e43
    result.e34 = a.e31 * b.e14 + a.e32 * b.e24 + a.e33 * b.e34 + a.e34 * b.e44

    result.e41 = a.e41 * b.e11 + a.e42 * b.e21 + a.e43 * b.e31 + a.e44 * b.e41
    result.e42 = a.e41 * b.e12 + a.e42 * b.e22 + a.e43 * b.e32 + a.e44 * b.e42
    result.e43 = a.e41 * b.e13 + a.e42 * b.e23 + a.e43 * b.e33 + a.e44 * b.e43
    result.e44 = a.e41 * b.e14 + a.e42 * b.e24 + a.e43 * b.e34 + a.e44 * b.e44


proc setPosition*(mx: var Matrix, x,y,z: float) =
    mx.e41 = x
    mx.e42 = y
    mx.e43 = z
    mx.e44 = 1


func setPosition*(mx: var Matrix, vec: Vec) =
    mx.e41 = vec.x
    mx.e42 = vec.y
    mx.e43 = vec.z
    mx.e44 = 1


proc translate*(mx: var Matrix, x,y,z : float) =
    mx.e11 += x * mx.e14
    mx.e12 += y * mx.e14
    mx.e13 += z * mx.e14

    mx.e21 += x * mx.e24
    mx.e22 += y * mx.e24
    mx.e23 += z * mx.e24
    
    mx.e31 += x * mx.e34
    mx.e32 += y * mx.e34
    mx.e33 += z * mx.e34

    mx.e41 += x * mx.e44
    mx.e42 += y * mx.e44
    mx.e43 += z * mx.e44


proc translate*(mx: var Matrix, vec: Vec) =
    mx.e11 += vec.x * mx.e14
    mx.e12 += vec.y * mx.e14
    mx.e13 += vec.z * mx.e14
    mx.e21 += vec.x * mx.e24
    mx.e22 += vec.y * mx.e24
    mx.e23 += vec.z * mx.e24
    mx.e31 += vec.x * mx.e34
    mx.e32 += vec.y * mx.e34
    mx.e33 += vec.z * mx.e34
    mx.e41 += vec.x * mx.e44
    mx.e42 += vec.y * mx.e44
    mx.e43 += vec.z * mx.e44


proc scale*(mx: var Matrix, x,y,z: float = 1) =
    mx.e11 *= x
    mx.e21 *= x
    mx.e31 *= x
    mx.e41 *= x

    mx.e12 *= y
    mx.e22 *= y
    mx.e32 *= y
    mx.e42 *= y

    mx.e13 *= z
    mx.e23 *= z
    mx.e33 *= z
    mx.e43 *= z


proc scale*(mx: var Matrix, vec: Vec) =
    mx.e11 *= vec.x
    mx.e21 *= vec.x
    mx.e31 *= vec.x
    mx.e41 *= vec.x

    mx.e12 *= vec.y
    mx.e22 *= vec.y
    mx.e32 *= vec.y
    mx.e42 *= vec.y

    mx.e13 *= vec.z
    mx.e23 *= vec.z
    mx.e33 *= vec.z
    mx.e43 *= vec.z


proc scale*(mx: var Matrix, vec: Vec2, z: float32) =
    mx.e11 *= vec.x
    mx.e21 *= vec.x
    mx.e31 *= vec.x
    mx.e41 *= vec.x

    mx.e12 *= vec.y
    mx.e22 *= vec.y
    mx.e32 *= vec.y
    mx.e42 *= vec.y

    mx.e13 *= z
    mx.e23 *= z
    mx.e33 *= z
    mx.e43 *= z


proc transpose*(mx: var Matrix) =
    var tmp: float
    tmp = mx.e12; mx.e12 = mx.e21; mx.e21 = tmp;
    tmp = mx.e13; mx.e13 = mx.e31; mx.e31 = tmp;
    tmp = mx.e14; mx.e14 = mx.e41; mx.e41 = tmp;
    tmp = mx.e23; mx.e23 = mx.e32; mx.e32 = tmp;
    tmp = mx.e24; mx.e24 = mx.e42; mx.e42 = tmp;
    tmp = mx.e34; mx.e34 = mx.e43; mx.e43 = tmp;


proc rotate*(mx: var Matrix, angle: float, x: float = 1, y,z: float) =
    var tmp = matrix()
    var x = x; var y = y; var z = z
    var len = sqrt(x*x+y*y+z*z)
    if len != 1.0 and len != 0.0:
        len = 1.0 / len
        x *= len
        y *= len
        z *= len
    
    var s = sin(-angle)
    var c = cos(-angle)
    var t = 1.0 - c

    tmp.e11 = x*x*t + c
    tmp.e12 = y*x*t + z*s
    tmp.e13 = z*x*t - y*s
    tmp.e14 = 0

    tmp.e21 = x*y*t - z*s
    tmp.e22 = y*y*t + c
    tmp.e23 = z*y*t + x*s
    tmp.e24 = 0

    tmp.e31 = x*z*t + y*s
    tmp.e32 = y*z*t - x*s
    tmp.e33 = z*z*t + c
    tmp.e34 = 0

    tmp.e41 = 0
    tmp.e42 = 0
    tmp.e43 = 0
    tmp.e44 = 1
    
    mx = mx * tmp


proc rotate*(mx: var Matrix, angle: float, axis: Vec) =
    var tmp = matrix()
    var x = axis.x; var y = axis.y; var z = axis.z
    var len = sqrt(x*x+y*y+z*z)
    if len != 1.0 and len != 0.0:
        len = 1.0 / len
        x *= len
        y *= len
        z *= len
    
    var s = sin(-angle)
    var c = cos(-angle)
    var t = 1.0 - c

    tmp.e11 = x*x*t + c
    tmp.e12 = y*x*t + z*s
    tmp.e13 = z*x*t - y*s
    tmp.e14 = 0

    tmp.e21 = x*y*t - z*s
    tmp.e22 = y*y*t + c
    tmp.e23 = z*y*t + x*s
    tmp.e24 = 0

    tmp.e31 = x*z*t + y*s
    tmp.e32 = y*z*t - x*s
    tmp.e33 = z*z*t + c
    tmp.e34 = 0

    tmp.e41 = 0
    tmp.e42 = 0
    tmp.e43 = 0
    tmp.e44 = 1
    
    mx = tmp * mx


proc invert*(mx: var Matrix) =
    let e11 = mx.e11
    let e12 = mx.e12
    let e13 = mx.e13
    let e14 = mx.e14
    let e21 = mx.e21
    let e22 = mx.e22
    let e23 = mx.e23
    let e24 = mx.e24 
    let e31 = mx.e31
    let e32 = mx.e32
    let e33 = mx.e33
    let e34 = mx.e34
    let e41 = mx.e41
    let e42 = mx.e42
    let e43 = mx.e43
    let e44 = mx.e44

    let b01 = e11*e22 - e12*e21
    let b02 = e11*e23 - e13*e21
    let b03 = e11*e24 - e14*e21
    let b04 = e12*e23 - e13*e22
    let b05 = e12*e24 - e14*e22
    let b06 = e13*e24 - e14*e23
    let b07 = e31*e42 - e32*e41
    let b08 = e31*e43 - e33*e41
    let b09 = e31*e44 - e34*e41
    let b10 = e32*e43 - e33*e42
    let b11 = e32*e44 - e34*e42
    let b12 = e33*e44 - e34*e43

    let det_inv = 1.0f/(b01*b12 - b02*b11 + b03*b10 + b04*b09 - b05*b08 + b06*b07)

    mx.e11 = ( e22*b12 - e23*b11 + e24*b10)*det_inv
    mx.e12 = (-e12*b12 + e13*b11 - e14*b10)*det_inv
    mx.e13 = ( e42*b06 - e43*b05 + e44*b04)*det_inv
    mx.e14 = (-e32*b06 + e33*b05 - e34*b04)*det_inv
    mx.e21 = (-e21*b12 + e23*b09 - e24*b08)*det_inv
    mx.e22 = ( e11*b12 - e13*b09 + e14*b08)*det_inv
    mx.e23 = (-e41*b06 + e43*b03 - e44*b02)*det_inv
    mx.e24 = ( e31*b06 - e33*b03 + e34*b02)*det_inv
    mx.e31 = ( e21*b11 - e22*b09 + e24*b07)*det_inv
    mx.e32 = (-e11*b11 + e12*b09 - e14*b07)*det_inv
    mx.e33 = ( e41*b05 - e42*b03 + e44*b01)*det_inv
    mx.e34 = (-e31*b05 + e32*b03 - e34*b01)*det_inv
    mx.e41 = (-e21*b10 + e22*b08 - e23*b07)*det_inv
    mx.e42 = ( e11*b10 - e12*b08 + e13*b07)*det_inv
    mx.e43 = (-e41*b04 + e42*b02 - e43*b01)*det_inv
    mx.e44 = ( e31*b04 - e32*b02 + e33*b01)*det_inv


proc inverse*(mx: Matrix): Matrix =
    let e11 = mx.e11
    let e12 = mx.e12
    let e13 = mx.e13
    let e14 = mx.e14
    let e21 = mx.e21
    let e22 = mx.e22
    let e23 = mx.e23
    let e24 = mx.e24 
    let e31 = mx.e31
    let e32 = mx.e32
    let e33 = mx.e33
    let e34 = mx.e34
    let e41 = mx.e41
    let e42 = mx.e42
    let e43 = mx.e43
    let e44 = mx.e44

    let b01 = e11*e22 - e12*e21
    let b02 = e11*e23 - e13*e21
    let b03 = e11*e24 - e14*e21
    let b04 = e12*e23 - e13*e22
    let b05 = e12*e24 - e14*e22
    let b06 = e13*e24 - e14*e23
    let b07 = e31*e42 - e32*e41
    let b08 = e31*e43 - e33*e41
    let b09 = e31*e44 - e34*e41
    let b10 = e32*e43 - e33*e42
    let b11 = e32*e44 - e34*e42
    let b12 = e33*e44 - e34*e43

    let det_inv = 1.0f/(b01*b12 - b02*b11 + b03*b10 + b04*b09 - b05*b08 + b06*b07)

    result.e11 = ( e22*b12 - e23*b11 + e24*b10)*det_inv
    result.e12 = (-e12*b12 + e13*b11 - e14*b10)*det_inv
    result.e13 = ( e42*b06 - e43*b05 + e44*b04)*det_inv
    result.e14 = (-e32*b06 + e33*b05 - e34*b04)*det_inv
    result.e21 = (-e21*b12 + e23*b09 - e24*b08)*det_inv
    result.e22 = ( e11*b12 - e13*b09 + e14*b08)*det_inv
    result.e23 = (-e41*b06 + e43*b03 - e44*b02)*det_inv
    result.e24 = ( e31*b06 - e33*b03 + e34*b02)*det_inv
    result.e31 = ( e21*b11 - e22*b09 + e24*b07)*det_inv
    result.e32 = (-e11*b11 + e12*b09 - e14*b07)*det_inv
    result.e33 = ( e41*b05 - e42*b03 + e44*b01)*det_inv
    result.e34 = (-e31*b05 + e32*b03 - e34*b01)*det_inv
    result.e41 = (-e21*b10 + e22*b08 - e23*b07)*det_inv
    result.e42 = ( e11*b10 - e12*b08 + e13*b07)*det_inv
    result.e43 = (-e41*b04 + e42*b02 - e43*b01)*det_inv
    result.e44 = ( e31*b04 - e32*b02 + e33*b01)*det_inv



proc ortho*(mx: var Matrix, left, right, bottom, top, znear, zfar : float) =
    let w = 1 / (right-left) # width
    let h = 1 / (top-bottom) # height
    let d = 1 / (zfar-znear) # depth

    mx.e11 = 2*w
    mx.e12 = 0
    mx.e13 = 0
    mx.e14 = 0

    mx.e21 = 0
    mx.e22 = 2*h
    mx.e23 = 0
    mx.e24 = 0

    mx.e31 = 0
    mx.e32 = 0
    mx.e33 = d
    mx.e34 = 0

    mx.e41 = -(right + left) * w
    mx.e42 = -(top + bottom) * h
    mx.e43 = -znear * d
    mx.e44 = 1


proc matrixOrtho*(left, right, bottom, top, znear, zfar : float): Matrix =
    let w = 1 / (right-left) # width
    let h = 1 / (top-bottom) # height
    let d = 1 / (zfar-znear) # depth
    result     = matrix()
    result.e11 = 2*w
    result.e12 = 0
    result.e13 = 0
    result.e14 = 0

    result.e21 = 0
    result.e22 = 2*h
    result.e23 = 0
    result.e24 = 0

    result.e31 = 0
    result.e32 = 0
    result.e33 = d
    result.e34 = 0

    result.e41 = -(right + left) * w
    result.e42 = -(top + bottom) * h
    result.e43 = -znear * d
    result.e44 = 1


proc frustrum(mx: var Matrix, left, right, bottom, top, znear, zfar: float) =
    let n2 = znear * 2
    let rl = right - left
    let tb = top   - bottom
    let fn = zfar  - znear
    
    mx.e11 = n2 / rl
    mx.e12 = 0
    mx.e13 = 0
    mx.e14 = 0

    mx.e21 = 0
    mx.e22 = n2 / tb
    mx.e23 = 0
    mx.e24 = 0

    mx.e31 = (right + left) / rl
    mx.e32 = (top + bottom) / tb
    mx.e33 = (zfar + znear) / fn
    mx.e34 = 1

    mx.e41 = 0
    mx.e42 = 0
    mx.e43 = -(zfar * n2) / fn
    mx.e44 = 0


proc perspective*(mx: var Matrix, fov, aspect, znear, zfar: float) =
    var top = znear * tan(fov.radians * 0.5)
    var right = top * aspect
    mx.frustrum(-right,right, -top,top, znear,zfar)



proc lookat*(eye: Vec, target: Vec, up: Vec): Matrix =
   var z = eye-target
   normalize(z)
   var x = cross(up, z)
   normalize(x)
   var y = cross(z,x)
   normalize(y)
 
   #echo z.x
   result.e11 = x.x
   result.e12 = x.y
   result.e13 = x.z
   result.e14 = 0

   result.e21 = y.x
   result.e22 = y.y
   result.e23 = y.z
   result.e24 = 0

   result.e31 = z.x
   result.e32 = z.y
   result.e33 = z.z
   result.e34 = 0

   result.e41 = -eye.x
   result.e42 = -eye.y
   result.e43 = -eye.z
   result.e44 = 1

   result.invert()