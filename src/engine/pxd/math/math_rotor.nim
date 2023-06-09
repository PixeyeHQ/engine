import std/math
import math_d
import math_matrix
import math_vector

when defined(v32):
    type float = float32

proc lensqr*(rotor: var Rotor3): float32 =
    return pow(rotor.a,2) + pow(rotor.b01,2) + pow(rotor.b02,2) + pow(rotor.b12,2)


proc len*(rotor: var Rotor3): float32 =
    return sqrt(lensqr(rotor))


proc normalize*(rotor: var Rotor3) =
    let len = rotor.len
    rotor.a   /= len
    rotor.b01 /= len
    rotor.b02 /= len
    rotor.b12 /= len


proc rotor3*(axisplane: BVec3, angle: float): Rotor3 =
    let rangle = angle.radians / 2f
    var asin   = sin(rangle)
    result.a   = cos(rangle)
    result.b01 = -asin * axisplane.b01
    result.b02 = -asin * axisplane.b02
    result.b12 = -asin * axisplane.b12


proc rotor3*(vfrom,vto: Vec3): Rotor3 =
    let bv   = wedge(vto, vfrom)
    result.a = 1 + dot(vto,vfrom)
    result.b01 = bv.b01
    result.b02 = bv.b02
    result.b12 = bv.b12
    normalize(result)


proc rotate*(rotor: var Rotor3, v: Vec3): Vec3 =
    var q: Vec3
    q.x = rotor.a * v.x + v.y * rotor.b01 + v.z * rotor.b02
    q.y = rotor.a * v.y - v.x * rotor.b01 + v.z * rotor.b12
    q.z = rotor.a * v.z - v.x * rotor.b02 - v.y * rotor.b12
    #trivec
    var q12  = v.x * rotor.b12 - v.y * rotor.b02 + v.z * rotor.b01
    
    result.x = rotor.a * q.x + q.y * rotor.b01 + q.z * rotor.b02 + q12 * rotor.b12 
    result.y = rotor.a * q.y - q.x * rotor.b01 - q12 * rotor.b02 + q.z * rotor.b12 
    result.z = rotor.a * q.z + q12 * rotor.b01 - q.x * rotor.b02 - q.y * rotor.b12 

proc mat3x3*(rotor: var Rotor3): Matrix3x3 =
    let v0 = rotor.rotate(vec(1,0,0))
    let v1 = rotor.rotate(vec(0,1,0))
    let v2 = rotor.rotate(vec(0,0,1))
    return matrix3(v0,v1,v2)

proc mat3x3opt*(rotor: var Rotor3): Matrix3x3 =
    var q:   Vec3
    var q12: float32
    let x = 1f
    let y = 1f
    let z = 1f
   
    # rotate vector around x
    q.x = rotor.a * x
    q.y = 0 - x * rotor.b01
    q.z = 0 - x * rotor.b02
    # trivec
    q12  = x * rotor.b12
    result.e11 = rotor.a * q.x + q.y * rotor.b01 + q.z * rotor.b02 + q12 * rotor.b12 
    result.e12 = rotor.a * q.y - q.x * rotor.b01 - q12 * rotor.b02 + q.z * rotor.b12 
    result.e13 = rotor.a * q.z + q12 * rotor.b01 - q.x * rotor.b02 - q.y * rotor.b12 

    # rotate vector around y
    q.x = y * rotor.b01
    q.y = rotor.a * y
    q.z = 0 - y * rotor.b12
    #trivec
    q12  = 0 - y * rotor.b02
    
    result.e21 = rotor.a * q.x + q.y * rotor.b01 + q.z * rotor.b02 + q12 * rotor.b12 
    result.e22 = rotor.a * q.y - q.x * rotor.b01 - q12 * rotor.b02 + q.z * rotor.b12 
    result.e23 = rotor.a * q.z + q12 * rotor.b01 - q.x * rotor.b02 - q.y * rotor.b12 

    # rotate vector around z
    q.x = z * rotor.b02
    q.y = z * rotor.b12
    q.z = rotor.a * z
    #trivec
    q12  = z * rotor.b01

    result.e31 = rotor.a * q.x + q.y * rotor.b01 + q.z * rotor.b02 + q12 * rotor.b12 
    result.e32 = rotor.a * q.y - q.x * rotor.b01 - q12 * rotor.b02 + q.z * rotor.b12 
    result.e33 = rotor.a * q.z + q12 * rotor.b01 - q.x * rotor.b02 - q.y * rotor.b12 

proc mat3x3opt2*(rotor: var Rotor3): Matrix3x3 =    
    var qx,qy,qz,q12: float
   
    # rotate around x
    qx  =  rotor.a
    qy  = -rotor.b01
    qz  = -rotor.b02
    q12 =  rotor.b12
    
    result.e11 = rotor.a * qx + qy * rotor.b01 +  qz * rotor.b02 + q12 * rotor.b12 
    result.e12 = rotor.a * qy - qx * rotor.b01 - q12 * rotor.b02 +  qz * rotor.b12 

    # rotate around y
    qx  =  rotor.b01
    qy  =  rotor.a
    qz  = -rotor.b12
    q12 = -rotor.b02
    
    result.e21 = rotor.a * qx + qy * rotor.b01 +  qz * rotor.b02 + q12 * rotor.b12
    result.e22 = rotor.a * qy - qx * rotor.b01 - q12 * rotor.b02 +  qz * rotor.b12

    # rotate around z
    qx  = rotor.b02
    qy  = rotor.b12
    qz  = rotor.a
    q12 = rotor.b01

    result.e31 = rotor.a * qx + qy * rotor.b01 +  qz * rotor.b02 + q12 * rotor.b12
    result.e32 = rotor.a * qy - qx * rotor.b01 - q12 * rotor.b02 +  qz * rotor.b12