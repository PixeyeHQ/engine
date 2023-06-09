import std/math as std_math
import math/[
  math_d,
  math_extensions,
  math_matrix,
  math_quaternion,
  math_rotor,
  math_vector
]

export
  math_d,
  math_extensions,
  math_matrix,
  math_quaternion,
  math_rotor,
  math_vector

export std_math except
    clamp,
    gcd,
    lcm