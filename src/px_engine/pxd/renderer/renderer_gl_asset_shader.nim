import std/os
import std/strformat
import std/strutils
import std/tables
import px_engine/vendor/gl
import px_engine/pxd/definition/api
import px_engine/pxd/m_debug
import px_engine/pxd/m_math
import px_engine/pxd/data/data_mem_pool
import renderer_gl_asset_shader_d
export renderer_gl_asset_shader_d


const defaultVert: string = """#version 330 core
  layout (location = 0) in vec3 position;
  void main()
  {
  gl_position = vec4(position.x, position.y, 0.0, 1.0);
  }"""
const defaultFrag: string = """
  #version 330 core
  out vec4 color;
  void main()
  {
  color = vec4(1,.5f,.2f,1);
  }"""


GEN_MEM_POOL(ShaderObject, Shader)


let debug = pxd.debug
let io    = pxd.io
#------------------------------------------------------------------------------------------
# @api shader logger
#------------------------------------------------------------------------------------------
proc reportShaderCompilation(api: DebugAPI, source: GLuint, reportType: GLenum): tuple[success: bool, error: string] =
  var success: GLint
  var infoLog = newString(1024).cstring
  case reportType:
  of GL_COMPILE_STATUS:
    glGetShaderiv(source, reportType, success.addr)
  of GL_LINK_STATUS:
    glGetProgramiv(source, reportType, success.addr)
  else:
    discard
  if success == 0:
    result = (success: false, error: $infoLog)
  else:
    result = (success: true, error: "")


proc reportShaderCompilation*(api: DebugAPI, vert, frag: GLuint) =
  var report: tuple[success: bool, error: string] 
  report = api.reportShaderCompilation(vert, GL_COMPILE_STATUS)
  if not report.success:
      pxd.debug.error("[SHADER]: Vertex shader compilation failed: " & report.error)
  report = api.reportShaderCompilation(frag, GL_COMPILE_STATUS)
  if not report.success:
      pxd.debug.error("[SHADER]: Fragment shader compilation failed: " & report.error)


proc reportShaderCompilation(api: DebugAPI, shader: GLuint) =
  var report: tuple[success: bool, error: string]
  report = api.reportShaderCompilation(shader, GL_LINK_STATUS)
  if not report.success:
      pxd.debug.error("[SHADER]: Shader program linking failed: " & report.error)


proc report(api: DebugAPI, error: ShaderError, args: varargs[string]) =
  case error:
    of RE_SHADER_NO_FRAG_FILE:
      pxd.debug.warn(&"[ASSET]: The path {args[0]} doesn't exist, adding a default fragment shader.")
    of RE_SHADER_NO_VERT_FILE:
      pxd.debug.warn(&"[ASSET]: The path {args[0]} doesn't exist, adding a default vertex shader.")


#------------------------------------------------------------------------------------------
# @api shader loader
#------------------------------------------------------------------------------------------
proc compileShader(mtype: GLenum, source: string): GLuint =
  let shader = glCreateShader(mtype)
  var source = [cstring(source)]
  glShaderSource(shader, 1, cast[cstringArray](source.addr), nil)
  glCompileShader(shader)
  result = shader


proc load*(api: EngineAPI, pathFull: string, typeof: typedesc[Shader]): Shader = 
  let assetPath  = io.pathWithoutExtension(pathFull)
  var sourceFrag = defaultFrag
  var sourceVert = defaultVert
  var path = default(string)
  path = assetPath & ".vert"
  if not fileExists(path):
    pxd.debug.report(RE_SHADER_NO_VERT_FILE, path)
  else: sourceVert = readFile(path)
  path = assetPath & ".frag"
  if not fileExists(path):
    pxd.debug.report(RE_SHADER_NO_FRAG_FILE, path)
  else: sourceFrag = readFile(path)
  var vertex = compileShader(GL_VERTEX_SHADER, sourceVert)
  var frag   = compileShader(GL_FRAGMENT_SHADER, sourceFrag)
  pxd.debug.reportShaderCompilation(vertex, frag)
  var shader = glCreateProgram()
  glAttachShader(shader, vertex)
  glAttachShader(shader, frag)
  glLinkProgram(shader)
  pxd.debug.reportShaderCompilation(shader)
  glDeleteShader(vertex)
  glDeleteShader(frag)
  result = make(ShaderObject)
  result.program = shader


proc unload*(api: EngineAPI, shader: Shader) =
  glDeleteProgram(shader.program)
  shader.drop()


#------------------------------------------------------------------------------------------
# @api shader usage
#------------------------------------------------------------------------------------------
proc use*(api: RenderAPI_Internal, shader: Shader) =
  glUseProgram(shader.get.program)


proc stop*(api: RenderAPI_Internal, shader: Shader) =
  glUseProgram(0)


#------------------------------------------------------------------------------------------
# @api uniforms
#------------------------------------------------------------------------------------------
var uniformNames: array[64, TableRef[string, i32]]
for index in 0..<64:
  uniformNames[index] = newTable[string, i32]()


proc getUniformLocation(shader: Shader, name: string): i32 {.inline.} =
  let shaderId = shader.get.program.u32
  let table    = uniformNames[shaderId]
  if table.hasKey(name):
    result = table[name]
  else:
    result = glGetUniformLocation(shaderId, name)
    table[name] = result


proc getUniformLocation*(api: RenderAPI_Internal, shader: Shader, name: string): i32 {.inline.} =
  getUniformLocation(shader, name)


proc uniform*(shader: Shader, name: string, value: i32) =
  glUniform1i(getUniformLocation(shader,name),value)


proc uniform*(shader: Shader, name: string, count: int, value: ptr i32) =
  glUniform1iv(getUniformLocation(shader,name),int32(count), cast[ptr GLint](value))


proc uniform*(shader: Shader, name: string, value: f32) =
  glUniform1f(getUniformLocation(shader,name),value)


proc uniform*(shader: Shader, name: string, x,y,z,w: f32) =
  glUniform4f(getUniformLocation(shader,name),x,y,z,w)


proc uniform*(shader: Shader, name: string, value: Vec) =
  uniform(shader, name, value.x, value.y, value.z, value.w)


proc uniform*(shader: Shader, name: string, matrix: var Matrix) =
  glUniformMatrix4fv(getUniformLocation(shader,name), 1, false, matrix.e11.addr)


#------------------------------------------------------------------------------------------
# @api dump
#------------------------------------------------------------------------------------------
#[
[*]loadShader
    echo assetName
    var numAttrs: GLint = 0
    glGetProgramiv(result.program, GlActiveAttributes, numAttrs.addr)
    echo numAttrs
    for i in 0..<numAttrs:
      var alen: GLsizei
      var asize: GLint
      var atype: GLenum
      var aname: cstring = cast[cstring](alloc(256))
      glGetActiveAttrib(result.program, i.GLuint, 256, alen.addr, asize.addr, atype.addr, aname)
      let aloc = glGetAttribLocation(result.program, aname)
      echo aname
    # result.attributes[aname] = ShaderAttr(name: aname, size: asize, length: alen, gltype: atype, location: aloc)
]#
