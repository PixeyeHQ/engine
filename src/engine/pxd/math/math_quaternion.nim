# 📖 https://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/index.htm
# 📖 https://www.3dgep.com/understanding-quaternions/
import std/math
import math_d

when defined(v32):
    type float = float32

proc quat*(axis: Vec3, angle: float): Quat =
    ## Axis must be normalized.
    let rangle = angle.radians / 2f
    var asin   = sin(rangle)
    result.w   = cos(rangle)
    result.x = asin * axis.x
    result.y = asin * axis.y
    result.z = asin * axis.z


proc quatx*(angle: float): Quat =
    let rangle = angle.radians / 2f
    var asin   = sin(rangle)
    result.w   = cos(rangle)
    result.x = asin
    result.y = 0
    result.z = 0


proc quaty*(angle: float): Quat =
    let rangle = angle.radians / 2f
    var asin   = sin(rangle)
    result.w   = cos(rangle)
    result.x = 0
    result.y = asin
    result.z = 0


proc quatz*(angle: float): Quat =
    let rangle = angle.radians / 2f
    var asin   = sin(rangle)
    result.w   = cos(rangle)
    result.x = 0
    result.y = 0
    result.z = asin


proc rotate*(sq: var Quat, v: Vec3): Vec3 =
    var qx,qy,qz,qw: float
    qx =   sq.w * v.x + sq.y * v.z - sq.z * v.y
    qy =   sq.w * v.y + sq.z * v.x - sq.x * v.z
    qz =   sq.w * v.z + sq.x * v.y - sq.y * v.x
    qw = - sq.x * v.x - sq.y * v.y - sq.z * v.z

    result.x = qw * -sq.x + sq.w * qx - qy * sq.z + qz * sq.y
    result.y = qw * -sq.y + sq.w * qy - qz * sq.x + qx * sq.z
    result.z = qw * -sq.z + sq.w * qz - qx * sq.y + qy * sq.x


proc mat3x2*(q: var Quat): Matrix3x2 =
    let xx = q.x * q.x
    let xy = q.x * q.y
    let xz = q.x * q.z
    let xw = q.x * q.w
    let yy = q.y * q.y
    let yz = q.y * q.z
    let yw = q.y * q.w
    let zz = q.z * q.z
    let zw = q.z * q.w

    result.e11 = 1 - 2 * (yy+zz)
    result.e12 = 2     * (xy+zw)
    result.e21 = 2     * (xy-zw)
    result.e22 = 1 - 2 * (xx+zz)
    result.e31 = 2     * (xz+yw)
    result.e32 = 2     * (yz-xw)


proc setEuler*(q: var Quat, angles: Vec3) =
    var sx  = sin(angles.x * 0.5)
    var cx  = cos(angles.x * 0.5)
    var sy  = sin(angles.y * 0.5)
    var cy  = cos(angles.y * 0.5)
    var sz  = sin(angles.z * 0.5)
    var cz  = cos(angles.z * 0.5)
    
    q.x =  (cy*sx*cz) + (sy*cx*sz)
    q.y = -(sy*cx*cz) - (cy*sx*sz)
    q.z =  (cy*cx*sz) - (sy*sx*cz)
    q.w = -(cy*cx*cz) + (sy*sx*sz)


proc mat4x4*(q: var Quat): Matrix =
    let xx = q.x * q.x
    let xy = q.x * q.y
    let xz = q.x * q.z
    let xw = q.x * q.w
    let yy = q.y * q.y
    let yz = q.y * q.z
    let yw = q.y * q.w
    let zz = q.z * q.z
    let zw = q.z * q.w

    result.e11 = 1 - 2 * (yy+zz)
    result.e12 = 2     * (xy+zw)
    result.e13 = 2     * (xz-yw)
    result.e14 = 0
    result.e21 = 2     * (xy-zw)
    result.e22 = 1 - 2 * (xx+zz)
    result.e23 = 2     * (yz+xw)
    result.e24 = 0
    result.e31 = 2     * (xz+yw)
    result.e32 = 2     * (yz-xw)
    result.e33 = 1 - 2 * (xx+yy)
    result.e34 = 0
    result.e41 = 0
    result.e42 = 0
    result.e43 = 0
    result.e44 = 1