import std/strutils
import std/strformat
import api
export strformat.`&`


const
  lv_echo* = 4'u8
  lv_debug* = 3'u8
  lv_info* = 2'u8
  lv_warn* = 1'u8
  lv_error* = 0'u8
  log_level {.intdefine.}: uint8 = lv_echo
const
  names_std: array[5, string] = ["\e[0;31mERROR:\e[39m", "\e[0;33mWARN:\e[39m", "\e[0;34mINFO:\e[39m",
      "\e[0;32mLOG:\e[39m", ""]
  names: array[5, string] = ["ERROR:", "WARN:", "INFO:", "LOG:", ""]
  log_template = "$# $# $#$#"
  log_template_std = "$# $#$#"
  log_template_echo_std = "$#"
type
  MessageKind = enum
    Write, Trace, Update, Stop
  Message = object
    case kind: MessageKind
      of Write:
        w_txt: string
        w_lvl: uint8
      of Trace:
        t_stack: seq[StackTraceEntry]
        t_txt: string
        t_lvl: uint8
      of Update:
        logs: seq[File]
      of Stop:
        nil


proc sendLogTraced(level: uint8 = 0, args: varargs[string, `$`])
proc sendLog (level: uint8 = 0, args: varargs[string, `$`])
proc addLog*(api: DebugAPI, file_name: string)
proc addLog*(api: DebugAPI, file: File)
proc cutTrace*(api: DebugAPI, steps: int)


var
  g_cut_trace_steps = 0
  thread: Thread[void]
  channel: Channel[Message]
  logs: seq[File]


#------------------------------------------------------------------------------------------
# @api logger
#------------------------------------------------------------------------------------------
template print*(api: DebugAPI, args: varargs[string, `$`]) =
  when log_level >= lv_echo:
    sendLog(lv_echo, args)

template log*(api: DebugAPI, args: varargs[string, `$`]) =
  when log_level >= lv_debug:
    sendLogTraced(lv_debug, args)

template info*(api: DebugAPI, args: varargs[string, `$`]) =
  sendLog(lv_info, args)

template warnTraced*(api: DebugAPI, args: varargs[string, `$`]) =
  when log_level >= lv_warn:
    sendLogTraced(lv_warn, args)

template error*(api: DebugAPI, args: varargs[string, `$`]) =
  when log_level >= lv_error:
    sendLogTraced(lv_error, args)

template warn*(api: DebugAPI, args: varargs[string, `$`]) =
  when log_level >= lv_warn:
    sendLog(lv_warn, args)


proc cutTrace*(api: DebugAPI, steps: int) =
  g_cut_trace_steps = steps

proc sendLog(level: uint8, args: varargs[string]) =
  var w_msg = Message(kind: Write)
  w_msg.w_lvl = level
  w_msg.w_txt.setLen(0)
  for arg in args.items:
    w_msg.w_txt.add arg
  w_msg.w_txt.add "\n"
  channel.send w_msg

proc sendLogTraced(level: uint8, args: varargs[string]) =
  var t_msg = Message(kind: Trace)
  t_msg.t_lvl = level
  if g_cut_trace_steps > 0:
    var tr = getStackTraceEntries()
    tr.setLen(tr.len-g_cut_trace_steps)
    t_msg.t_stack = tr
  else:
    var tr = getStackTraceEntries()
    t_msg.t_stack = tr
  t_msg.t_txt.setLen(0)
  for arg in args:
    t_msg.t_txt.add arg
  t_msg.t_txt.add "\n"
  channel.send t_msg
proc logThreadLoop() {.thread.} =
  var
    logs: seq[File]
  while true:
    let msg = recv channel
    case msg.kind
    of Update:
      logs = msg.logs
    of Write:
      var text_log = ""
      var text_log_std = ""
      if msg.w_lvl == lv_echo:
        text_log = log_template_echo_std % [msg.w_txt]
        text_log_std = log_template_echo_std % [msg.w_txt]
      else:
        text_log = log_template_std % [names[msg.w_lvl], "", msg.w_txt]
        text_log_std = log_template_std % [names_std[msg.w_lvl], "", msg.w_txt]
      logs[0].write text_log_std
      if channel.peek == 0:
        logs[0].flushFile
      for i in 1..logs.high:
        let log = logs[i].addr
        log[].write text_log
        if channel.peek == 0:
          log[].flushFile
    of Trace:
      var text_log = ""
      var text_log_std = ""
      var text_trace = ""
      text_log = &"{names[msg.t_lvl]} {msg.t_txt}"
      text_log_std = log_template_std % [names_std[msg.t_lvl], "", msg.t_txt]
      var sym = "⯆"
      var len = msg.t_stack.high-1
      for i in 0..len:
        var n = msg.t_stack[i]
        if i == len:
          sym = "⯈"
        text_trace.add(&"{sym} {n.filename} ({n.line}) {n.procname}\n")

      text_log.add(text_trace)
      text_log_std.add(text_trace)

      logs[0].write text_log_std
      if channel.peek == 0:
        logs[0].flushFile
      for i in 1..logs.high:
        let log = logs[i].addr
        log[].write text_log
        if channel.peek == 0:
          log[].flushFile
    of Stop:
      break

proc addLog*(api: DebugAPI, file: File) =
  logs.add(file)
  channel.send Message(kind: Update, logs: logs)
proc addLog*(api: DebugAPI, fileName: string) =
  assert fileName != "", "no file name provided"
  api.addLog(open(file_name, fmWrite))

proc init*(api: DebugAPI) =
  open(channel)
  pxd.debug.addLog(stdout)
  createThread(thread, logThreadLoop)
proc shutdown*(api: DebugAPI) {.noconv.} =
  channel.send Message(kind: Stop)
  joinThread thread
  close channel
  for log in logs:
    if log notin [stdout, stderr]:
      close log

proc terminateApp(api: DebugAPI) =
  api.shutdown()
  quit(0)

#------------------------------------------------------------------------------------------
# @api errors
#------------------------------------------------------------------------------------------
proc fatal*(api: DebugAPI, message: string) =
  pxd.debug.cutTrace(1)
  pxd.debug.error(message)
  pxd.debug.terminateApp()


proc fatal*(api: DebugAPI, message: string, traceCutSteps: int) =
  pxd.debug.cutTrace(1 + traceCutSteps)
  pxd.debug.error(message)
  pxd.debug.terminateApp()


#------------------------------------------------------------------------------------------
# @api assertions
#------------------------------------------------------------------------------------------
template assert*(api: DebugAPI, source: untyped) =
  when defined(debug):
    block:
      let tag {.inject.} = source[1]
      let desc {.inject.} = source[2]
      if not source[0]:
        pxd.debug.error(&"{tag}: {desc}")


template require*(api: DebugAPI, pmessage: string, pfileName: string, pprocName: string): string =
  when defined(debug):
    pmessage
  else:
    block:
      let message {.inject.} = pmessage
      let filename {.inject.} = pfileName
      let procname {.inject.} = pprocName
      &"{message}\n⯈ {filename} {procname}"


pxd.debug.init()
