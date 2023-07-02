import px_engine/vendor/gl
import px_engine/vendor/stb_image
import px_engine/pxd/definition/api
import px_engine/pxd/m_platform
import px_engine/pxd/m_debug
import px_engine/pxd/m_vars
import px_engine/pxd/m_math
import px_engine/tools/m_utils_collections
import renderer_gl_d

let debug = pxd.debug
let io    = pxd.io
#------------------------------------------------------------------------------------------
# @api renderer define
#------------------------------------------------------------------------------------------
var render      = RenderAPI_Internal(api_o)
var renderFrame = RenderFrame()


proc internal*(api: RenderAPI): RenderAPI_Internal =
  render


proc frame*(api: RenderAPI): var RenderFrame {.inline.} =
  ## Renderer frame state. 
  renderFrame


#------------------------------------------------------------------------------------------
# @api opengl utils
#------------------------------------------------------------------------------------------
proc getAttributeInfo(vatype: VertexAttributeType): tuple[paramsCount: i32, attributeType: u32] =
  case (vatype):
    of float1:
      result = (paramsCount: i32(1), attributeType: u32(cGL_FLOAT))
    of float2:
      result = (paramsCount: i32(2), attributeType: u32(cGL_FLOAT))
    of float3:
      result = (paramsCount: i32(3), attributeType: u32(cGL_FLOAT))
    of float4:
      result = (paramsCount: i32(4), attributeType: u32(cGL_FLOAT))


proc rdSizeof*(typeId: u32): i32 =
  case typeId:
  of cGL_FLOAT:        result = i32(sizeof(GLfloat))
  of GL_UNSIGNED_INT:  result = i32(sizeof(GLuint))
  of GL_UNSIGNED_BYTE: result = i32(sizeof(GLByte))
  else:
    assert false
    result = 0


#------------------------------------------------------------------------------------------
# @api opengl initialize
#------------------------------------------------------------------------------------------
proc glReport(source: Glenum, typ: Glenum, id: Gluint, severity: Glenum,
  length: GLsizei, message: ptr GLchar, userParam: pointer) {.stdcall, used.} = 
  # ignore non-significant codes.
  if (id == 131169 or id == 131185 or id == 131218 or id == 131204): return
  var rsource:    cstring
  var rtype:      cstring
  var rseverity:  cstring
  var shouldquit = false
  let trace      = getStackTraceEntries()[^2] 
  case source:
  of GL_DEBUG_SOURCE_API:             rsource = "API"
  of GL_DEBUG_SOURCE_WINDOW_SYSTEM:   rsource = "Window System"
  of GL_DEBUG_SOURCE_SHADER_COMPILER: rsource = "Shader Compiler"
  of GL_DEBUG_SOURCE_THIRD_PARTY:     rsource = "Third Party"
  of GL_DEBUG_SOURCE_APPLICATION:     rsource = "Application"
  of GL_DEBUG_SOURCE_OTHER:           rsource = "Other"
  else: rsource = ""
  case typ:
  of GL_DEBUG_TYPE_ERROR:               rtype = "Error"
  of GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR: rtype = "Deprecated Behaviour"
  of GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:  rtype = "Undefined Behaviour"
  of GL_DEBUG_TYPE_PORTABILITY:         rtype = "Portability"
  of GL_DEBUG_TYPE_PERFORMANCE:         rtype = "Performance"
  of GL_DEBUG_TYPE_MARKER:              rtype = "Marker"
  of GL_DEBUG_TYPE_PUSH_GROUP:          rtype = "Push Group"
  of GL_DEBUG_TYPE_POP_GROUP:           rtype = "Pop Group"
  of GL_DEBUG_TYPE_OTHER:               rtype = "Other"
  else: rtype = ""
  case severity:
  of GL_DEBUG_SEVERITY_HIGH:         rseverity = "Severity: \e[0;31mHigh\e[39m"; shouldquit = true
  of GL_DEBUG_SEVERITY_MEDIUM:       rseverity = "Severity: Medium";             shouldquit = true
  of GL_DEBUG_SEVERITY_LOW:          rseverity = "Severity: Low";                shouldquit = true
  of GL_DEBUG_SEVERITY_NOTIFICATION: rseverity = "Severity: Notification";       shouldquit = false
  else: rseverity = ""
  var messageFinal = cast[cstring](message)
  print &"[Opengl] {rsource} {rtype}; {rseverity}\n         {messageFinal}\n         ⯈ {trace.filename} ({trace.line})"
  if shouldquit:
    quit(0)


proc glInitDebugMode() =
  when defined(debug):
    glEnable(GL_DEBUG_OUTPUT)
    glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS)
    glDebugMessageCallback(glReport, nil)
    glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, nil, true)


proc reportGladLoadGl(api: DebugAPI, isGlLoaded: bool) =
  if isGlLoaded == true:
    let glversion {.inject.} = cast[cstring](glGetString(GL_VERSION))
    let glvendor  {.inject.} = cast[cstring](glGetString(GL_VENDOR))
    let message = &"\n GPU: {glversion}\n {glvendor}"
    pxd.vars.get("runtime.initMessage", string)[].add(message)
  else:
    pxd.debug.fatal("Renderer", "Can't initialize OpenGL!")


proc glInit() =
  type ProcAddress = proc(procname: cstring): proc() {.cdecl.} {.cdecl.}
  var glProc   = pxd.platform.initGl()
  let glResult = gladLoadGL(cast[ProcAddress](glProc))
  pxd.debug.reportGladLoadGl(glResult)


proc init*(api: RenderAPI) =
  pxd.platform.init()
  pxd.platform.createWindow()
  pxd.platform.createGlContext()
  glInit()
  glInitDebugMode()
 # glCullFace(GL_BACK)                                # Cull the back face (default)
 # glFrontFace(GL_CCW)                                # Front face are defined counter clockwise (default)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  glEnable(GL_BLEND)
 # glDepthFunc(GL_LEQUAL)
 # glEnable(GL_DEPTH_TEST)


#------------------------------------------------------------------------------------------
# @api opengl vertex arrays
#------------------------------------------------------------------------------------------
proc use*(api: RenderAPI_Internal, self: var VertexArray) =  
  glBindVertexArray(self.id)


proc stop*(api: RenderAPI_Internal, self: var VertexArray) =
  glBindVertexArray(0)


proc delete*(api: RenderAPI_Internal, self: var VertexArray) =
  glDeleteVertexArrays(1, self.id.addr)


proc addVertexArray*(api: RenderAPI_Internal): VertexArray =
  glGenVertexArrays(1, result.id.addr)
  glBindVertexArray(result.id)


proc addLayout*(self: var VertexArray, layout: VertexLayout) =
  self.layout = layout
  for index, attribute in mpairs[u32, var VertexAttribute](self.layout.elements):
    let info = getAttributeInfo(attribute.vtype)
    glVertexAttribPointer(index, info.paramsCount, info.attributeType, attribute.normalized, 
      layout.stride, cast[pointer](attribute.offset))
    glEnableVertexAttribArray(index)


#------------------------------------------------------------------------------------------
# @api opengl vertex buffers
#------------------------------------------------------------------------------------------
proc use*(api: RenderAPI_Internal, self: var VertexBuffer) =
  glBindBuffer(GL_ARRAY_BUFFER, self.id)


proc stop*(api: RenderAPI_Internal, self: var VertexBuffer) =
  glBindBuffer(GL_ARRAY_BUFFER, 0)


proc delete*(api: RenderAPI_Internal, self: var VertexBuffer) =
  glDeleteBuffers(1, self.id.addr)


proc addVertexBuffer*(api: RenderAPI_Internal, vertexType: typedesc, count: int): VertexBuffer =
  glGenBuffers(1, result.id.addr)
  glBindBuffer(GL_ARRAY_BUFFER, result.id)
  glBufferData(GL_ARRAY_BUFFER, (sizeof(vertexType)*count).cint, nil, GL_DYNAMIC_DRAW)


proc add*(layout: var VertexLayout, vaType: VertexAttributeType, name: string, normalized: bool = false) =
  var attribute: VertexAttribute
  let attributeInfo = getAttributeInfo(vaType)
  attribute.vtype      = vaType
  attribute.name       = name
  attribute.normalized = normalized
  attribute.offset     = layout.stride
  layout.stride += i32(attributeInfo.paramsCount * rdsizeof(attributeInfo.attributeType))
  layout.elements.add(attribute)


proc initVertexLayout*(api: RenderAPI_Internal): VertexLayout =
  result.elements = newseq[VertexAttribute]()


#---------------------------------------------------------------------------------------------
# @api index buffers
#---------------------------------------------------------------------------------------------
using self: var IndexBuffer


proc exists*(api: RenderAPI_Internal,self;): bool =
  result = self.id != 0


proc use*(api: RenderAPI_Internal, self;) =
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.id)


proc stop*(api: RenderAPI_Internal, self;) =
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)


proc delete*(api: RenderAPI_Internal, self;) =
  glDeleteBuffers(1, self.id.addr)


proc addIndexBuffer*(api: RenderAPI_Internal, data: pointer, count: int): IndexBuffer =
  var ib: IndexBuffer
  ib.count = count.i32
  glGenBuffers(1, ib.id.addr)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ib.id)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, (count * sizeof(GLuint)).cint, data, GL_STATIC_DRAW)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
  result = ib


