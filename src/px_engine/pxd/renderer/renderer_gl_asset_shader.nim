import std/[tables, os, strformat, strutils]
import ../[api, m_debug, m_memory, m_math, m_filesystem]
import ../../vendors/[gl]
import ../../assets/[asset_pack]


type
  ShaderError* = enum
    RE_SHADER_NO_VERT_FILE,
    RE_SHADER_NO_FRAG_FILE
  ShaderObj* = object
    program*: uint32
const
  defaultVert: string = """#version 330 core
    layout (location = 0) in vec3 position;
    void main()
    {
    gl_position = vec4(position.x, position.y, 0.0, 1.0);
    }"""
  defaultFrag: string = """
    #version 330 core
    out vec4 color;
    void main()
    {
    color = vec4(1,.5f,.2f,1);
    }"""


pxd.memory.genPool(Shader, ShaderObj)
var shaderAssets = initTable[string, Shader]()


#------------------------------------------------------------------------------------------
# @api shader logger
#------------------------------------------------------------------------------------------
proc reportShaderCompilation(api: DebugAPI, source: GLuint,
    reportType: GLenum): tuple[success: bool, error: string] =
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
    pxd.debug.error("SHADER: Vertex shader compilation failed: " & report.error)
  report = api.reportShaderCompilation(frag, GL_COMPILE_STATUS)
  if not report.success:
    pxd.debug.error("SHADER: Fragment shader compilation failed: " & report.error)

proc reportShaderCompilation(api: DebugAPI, shader: GLuint) =
  var report: tuple[success: bool, error: string]
  report = api.reportShaderCompilation(shader, GL_LINK_STATUS)
  if not report.success:
    pxd.debug.error("SHADER: Shader program linking failed: " & report.error)

proc report(api: DebugAPI, error: ShaderError, args: varargs[string]) =
  case error:
    of RE_SHADER_NO_FRAG_FILE:
      pxd.debug.warn(&"ASSET: The path {args[0]} doesn't exist, adding a default fragment shader.")
    of RE_SHADER_NO_VERT_FILE:
      pxd.debug.warn(&"ASSET: The path {args[0]} doesn't exist, adding a default vertex shader.")


#------------------------------------------------------------------------------------------
# @api shader loader
#------------------------------------------------------------------------------------------

proc compileShader(mtype: GLenum, source: string): GLuint =
  let shader = glCreateShader(mtype)
  var source = [cstring(source)]
  glShaderSource(shader, 1, cast[cstringArray](source.addr), nil)
  glCompileShader(shader)
  result = shader


proc load*(api: AssetAPI, pathRelative: string, typeof: typedesc[Shader]): Shader =
  let pathFull   = pxd.filesystem.path(pathRelative)
  let assetPath  = pxd.filesystem.trimExtension(pathFull)
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
  result = make(Shader)
  result.program = shader


proc unload*(api: AssetAPI, shader: Shader) =
  glDeleteProgram(shader.program)
  shader.drop()


proc load*(pack: AssetPack, relativePath: string, typeof: typedesc[Shader]): Shader {.discardable.} =
  var tag = relativePath & $typeof
  result = pxd.assets.load(relativePath, typeof)
  pack.items[tag] = (Handle)result


#------------------------------------------------------------------------------------------
# @api shader usage
#------------------------------------------------------------------------------------------
proc use*(api: RenderAPI, shader: Shader) =
  glUseProgram(shader.get.program)


proc stop*(api: RenderAPI, shader: Shader) =
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


proc getUniformLocation*(api: RenderAPI, shader: Shader, name: string): i32 {.inline.} =
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


# #------------------------------------------------------------------------------------------
# # @api dump
# #------------------------------------------------------------------------------------------
# #[
# [*]loadShader
#     echo assetName
#     var numAttrs: GLint = 0
#     glGetProgramiv(result.program, GlActiveAttributes, numAttrs.addr)
#     echo numAttrs
#     for i in 0..<numAttrs:
#       var alen: GLsizei
#       var asize: GLint
#       var atype: GLenum
#       var aname: cstring = cast[cstring](alloc(256))
#       glGetActiveAttrib(result.program, i.GLuint, 256, alen.addr, asize.addr, atype.addr, aname)
#       let aloc = glGetAttribLocation(result.program, aname)
#       echo aname
#     # result.attributes[aname] = ShaderAttr(name: aname, size: asize, length: alen, gltype: atype, location: aloc)
# ]#
