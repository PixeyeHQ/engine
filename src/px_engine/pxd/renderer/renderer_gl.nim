import ../../vendors/gl
import ../../vendors/stb_image
import ../../vendors/sdl
import ../../px_engine_toolbox
import ../m_vars
import ../m_debug
import ../m_platform
import ../api
import std/[strformat]
import renderer_d


var
  renderFrame = RenderFrame()
  render = RenderAPI_Private(api_o)

proc frame*(api: RenderAPI): RenderFrame {.inline.} =
  renderFrame


#------------------------------------------------------------------------------------------
# @api opengl initialize
#------------------------------------------------------------------------------------------
proc glReport(source: Glenum, typ: Glenum, id: Gluint, severity: Glenum,
  length: GLsizei, message: ptr GLchar, userParam: pointer) {.stdcall, used.} =
  # ignore non-significant codes.
  if (id == 131169 or id == 131185 or id == 131218 or id == 131204): return
  var rsource: cstring
  var rtype: cstring
  var rseverity: cstring
  var shouldquit = false
  let trace = getStackTraceEntries()[^2]
  case source:
  of GL_DEBUG_SOURCE_API: rsource = "API"
  of GL_DEBUG_SOURCE_WINDOW_SYSTEM: rsource = "Window System"
  of GL_DEBUG_SOURCE_SHADER_COMPILER: rsource = "Shader Compiler"
  of GL_DEBUG_SOURCE_THIRD_PARTY: rsource = "Third Party"
  of GL_DEBUG_SOURCE_APPLICATION: rsource = "Application"
  of GL_DEBUG_SOURCE_OTHER: rsource = "Other"
  else: rsource = ""
  case typ:
  of GL_DEBUG_TYPE_ERROR: rtype = "Error"
  of GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR: rtype = "Deprecated Behaviour"
  of GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR: rtype = "Undefined Behaviour"
  of GL_DEBUG_TYPE_PORTABILITY: rtype = "Portability"
  of GL_DEBUG_TYPE_PERFORMANCE: rtype = "Performance"
  of GL_DEBUG_TYPE_MARKER: rtype = "Marker"
  of GL_DEBUG_TYPE_PUSH_GROUP: rtype = "Push Group"
  of GL_DEBUG_TYPE_POP_GROUP: rtype = "Pop Group"
  of GL_DEBUG_TYPE_OTHER: rtype = "Other"
  else: rtype = ""
  case severity:
  of GL_DEBUG_SEVERITY_HIGH: rseverity = "Severity: \e[0;31mHigh\e[39m"; shouldquit = true
  of GL_DEBUG_SEVERITY_MEDIUM: rseverity = "Severity: Medium"; shouldquit = true
  of GL_DEBUG_SEVERITY_LOW: rseverity = "Severity: Low"; shouldquit = true
  of GL_DEBUG_SEVERITY_NOTIFICATION: rseverity = "Severity: Notification"; shouldquit = false
  else: rseverity = ""
  var messageFinal = cast[cstring](message)
  pxd.debug.print &"RENDERER: OPENGL: {rsource} {rtype}; {rseverity}\n         {messageFinal}\n         ⯈ {trace.filename} ({trace.line})"
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
    let glvendor {.inject.} = cast[cstring](glGetString(GL_VENDOR))
    let message = &"\n GPU: {glversion}\n {glvendor}"
    pxd.vars.get("runtime.initMessage", string)[].add(message)
  else:
    pxd.debug.fatal("RENDERER: Can't initialize OpenGL!")


proc glInit() =
  type ProcAddress = proc(procname: cstring): proc() {.cdecl.} {.cdecl.}
  var glProc = pxd.platform.initGl()
  let glResult = gladLoadGL(cast[ProcAddress](glProc))
  pxd.debug.reportGladLoadGl(glResult)


proc initRender*(api: EngineAPI) =
  pxd.platform.init()
  pxd.platform.createWindow()
  pxd.platform.createGlContext()
  glInit()
  glInitDebugMode()
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  glEnable(GL_BLEND)
# glCullFace(GL_BACK)                                # Cull the back face (default)
  # glFrontFace(GL_CCW)                                # Front face are defined counter clockwise (default)
  # glDepthFunc(GL_LEQUAL)
  # glEnable(GL_DEPTH_TEST)
