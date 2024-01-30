import px_pods
import std/[os]
import api
import m_vars
import ../toolbox/m_strings


let app_developer = pxd.vars.get("app.developer", string)
let app_title     = pxd.vars.get("app.title", string)


proc getAppDataDirectory*(api: FileSystemAPI): string =
  let developer = app_developer[].trim(' ')
  let title     = app_title[].trim(' ')
  return joinPath(getDataDir(),developer,title)
  # when defined(windows):
  #   return &"{getDataDir()}{developer}\\{title}\\"


proc path*(api: FileSystemAPI, relativePath: string): string =
  case relativePath[0]:
    of '.':
      result = joinPath(getAppDir(),"assets", substr(relativePath, 1))
    of '*':
      result = joinPath(api.getAppDataDirectory(), substr(relativePath, 1))
    else:
      result = "invalid path: " & relativePath


proc trimExtension*(api: FileSystemAPI, path: string): string = 
  let indexFrom = 0
  let indexTo   = searchExtPos(path) - 1
  result = substr(path, indexFrom, indexTo)


proc load*(api: VarsAPI, relativePath: string) =
  let path = pxd.filesystem.path(relativePath)
  if fileExists(path):
    px_pods.fromPodFile(path, pxd.vars.source)
  else:
    px_pods.toPodFile(path, pxd.vars.source, PodStyle.Sparse)


# #------------------------------------------------------------------------------------------
# # @api io paths
# #------------------------------------------------------------------------------------------
# proc path*(api: IoAPI, relativePath: string): string =
#   case relativePath[0]:
#     of '.':
#       result = getAppDir() & substr(relativePath, 1)
#     of '*':
#       result = app_io.dataPath & substr(relativePath, 1)
#     else:
#       result = "invalid path: " & relativePath


# proc pathExtension*(api: IoAPI, path: string): string =
#   let indexFrom = searchExtPos(path) + 1
#   let indexTo   = path.len
#   result = substr(path, indexFrom, indexTo)


# proc pathWithoutExtension*(api: IoAPI, path: string): string = 
#   let indexFrom = 0
#   let indexTo   = searchExtPos(path) - 1
#   result = substr(path, indexFrom, indexTo)