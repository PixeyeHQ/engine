
import std/strutils
import std/macros
import std/strformat
import std/tables
import std/monotimes
import std/times
import px_engine/pxd/definition/api
export strformat.`&`
export api.debug

#------------------------------------------------------------------------------------------
# @api logger define
#------------------------------------------------------------------------------------------



const lv_echo*  = 5'u8
const lv_trace* = 4'u8
const lv_debug* = 3'u8
const lv_info*  = 2'u8
const lv_warn*  = 1'u8
const lv_error* = 0'u8
const log_level* {.intdefine.}: uint8 = lv_info
const names_std: array[6, string] = ["\e[0;31mError:\e[39m", "\e[0;33mWarn:\e[39m", "\e[0;36mInfo:\e[39m", 
"\e[0;37mLog:\e[39m","\e[0;36mTrace:\e[39m", ""]
const names    : array[6, string] = ["Error:","Warn:","Info:","Log:","Trace:",""]
const log_template           = "$# $# $#$#" 
const log_template_std       = "$# $#$#"
const log_template_echo_std  = "$#"


type Logger* = object
  file: File


type MessageKind = enum
  Write,Trace,Update,Stop


type Message = object
  case kind: MessageKind
    of Write:
      w_txt  : string
      w_lvl  : uint8
    of Trace:
      t_stack: seq[StackTraceEntry]
      t_txt  : string
      t_lvl  : uint8
    of Update:
      u_logs:     seq[Logger]
      u_log_std : Logger
    of Stop:
      nil


proc inLogSendTrace(level: uint8 = 0, args: varargs[string, `$`], traceCut: int)
proc inLogSend     (level: uint8 = 0, args: varargs[string, `$`])
proc addLog*(api: DebugAPI, file_name:string)
proc addLog*(api: DebugAPI, file:File)
proc inLogCutTrace*(steps: int)


var g_cut_trace_steps = 0
var thread:     Thread[void]
var channel:    Channel[Message]
var logs:       seq[Logger]
var log_std:    Logger


#------------------------------------------------------------------------------------------
# @api logger
#------------------------------------------------------------------------------------------
template trace*(args: varargs[string, `$`], traceCut: int = 0) =
  when defined(debug):
    inLogSendTrace(lv_echo, args, traceCut)

proc print*(args: varargs[string, `$`]) =
    inLogSend(lv_echo, args)

template print*(api: DebugAPI, args: varargs[string, `$`]) =
  when defined(debug):
    inLogSend(lv_echo, args)

template ln*(args: varargs[string, `$`]) =
  inLogSend(lv_echo, args)
template log*(api: DebugAPI, args: varargs[string, `$`]) =
  inLogSendTrace(lv_echo, args, 0)
template info*(api: DebugAPI, args: varargs[string, `$`]) =
  inLogSend(lv_info,  args)
template warn*(api: DebugAPI, args: varargs[string, `$`], traceCut: int = 0) =
  when defined(debug):
    inLogSendTrace(lv_warn, args, traceCut)
  else:
    inLogSend(lv_warn,  args)
template error*(api: DebugAPI, args: varargs[string, `$`], traceCut: int = 0) =
  when defined(debug):
    inLogSendTrace(lv_error, args, traceCut)
  else:
    inLogSend(lv_error,  args)

proc inLogCutTrace*(steps: int) =
  g_cut_trace_steps = steps


proc inLogSend(level: uint8, args: varargs[string]) =
  var w_msg = Message(kind: Write)
  w_msg.w_lvl = level
  w_msg.w_txt.setLen(0)
  for arg in args:
    w_msg.w_txt.add arg
  w_msg.w_txt.add "\n"
  channel.send w_msg


proc inLogSendTrace(level: uint8, args: varargs[string], traceCut: int) =
  var t_msg = Message(kind: Trace)
  t_msg.t_lvl = level
  if traceCut > 0:
    var tr = getStackTraceEntries()
    tr.setLen(tr.len-traceCut)
    t_msg.t_stack = tr
  else:
    var tr = getStackTraceEntries()
    t_msg.t_stack = tr
  t_msg.t_txt.setLen(0)
  for arg in args:
    t_msg.t_txt.add arg
  t_msg.t_txt.add "\n"
  channel.send t_msg


proc inLogThreadStop* {.noconv.} =
  channel.send Message(kind: Stop)
  joinThread thread
  close channel
  for log in logs:
    if log.file notin [stdout, stderr]:
      close log.file


proc inLogThreadRun() {.thread.} =
  var 
    logs:      seq[Logger]
    log_std:   Logger
    time_prev: Time
    time_str = ""
  while true:
    let msg = recv channel
    case msg.kind
    of Update:
      logs    = msg.u_logs
      log_std = msg.u_log_std
    of Write:
      let time_new = getTime()
      if time_new != time_prev:
        time_prev = time_new
        time_str = local(time_new).format "HH:mm:ss"
      var text_log     = ""
      var text_log_std = ""
      if msg.w_lvl == lv_echo:
        text_log     = log_template_echo_std % [msg.w_txt]
        text_log_std = log_template_echo_std % [msg.w_txt]
      else:
        text_log     = log_template % [time_str,names[msg.w_lvl],"",msg.w_txt]
        text_log_std = log_template_std % [names_std[msg.w_lvl], "",msg.w_txt]

      for i in 0..logs.high:
        let log = logs[i].addr
        log.file.write text_log
        if channel.peek == 0:
          log.file.flushFile
      
      if not log_std.file.isNil:
        log_std.file.write text_log_std
        if channel.peek == 0:
            log_std.file.flushFile

    of Trace:
      let time_new = getTime()
      if time_new != time_prev:
        time_prev = time_new
        time_str = local(time_new).format "HH:mm:ss"

      var text_log = ""
      var text_log_std = ""
      var text_trace = ""

    # if (msg.t_lvl == lv_trace or msg.t_lvl == lv_error or msg.t_lvl == lv_warn):
      text_log = &"{time_str} {names[msg.t_lvl]} {msg.t_txt}"
      text_log_std = &"{names_std[msg.t_lvl]} {msg.t_txt}"
      var sym = "⯆"
      var len = msg.t_stack.high-1
      for i in 0..len:
        var n  =  msg.t_stack[i]
        if i==len:
          sym = "⯈"
        text_trace.add(&"{sym} {n.filename} ({n.line}) {n.procname}\n")
  
      text_log.add(text_trace)
      text_log_std.add(text_trace)
      # else:
      #   text_log = &"{time_str} {names[msg.t_lvl]} {msg.t_txt}"
      #   text_log_std = &"{names_std[msg.t_lvl]} {msg.t_txt}"
      #   var n  =  msg.t_stack[0]
      #   text_trace.add(&"⯈ {n.filename} ({n.line}) {n.procname}\n")

      #   text_log.add(text_trace)
      #   text_log_std.add(text_trace)

      for i in 0..logs.high:
        let log = logs[i].addr
        log.file.write text_log
        if channel.peek == 0:
          log.file.flushFile
      
      if not log_std.file.isNil:
        log_std.file.write text_log_std
        if channel.peek == 0:
            log_std.file.flushFile
    of Stop:
      break 


proc addLog*(api: DebugAPI, file:File) =
  if file == stdout:
    log_std = Logger(file: file)
  else:
    logs.add(Logger(file: file))
  channel.send Message(kind: Update, u_logs: logs, u_log_std: log_std)


proc addLog*(api: DebugAPI, file_name: string) =
  if file_name == "":
    echo "no file"
    return
  api.addLog(open(file_name,fmWrite))


#------------------------------------------------------------------------------------------
# @script logger
#------------------------------------------------------------------------------------------
proc init*(api: DebugAPI) =
  open(channel)
  pxd.debug.addLog(stdout)
  createThread(thread, inLogThreadRun)


proc shutdown*(api: DebugAPI) =
  inLogThreadStop()


proc terminateApp*(api: DebugAPI) =
  api.shutdown()
  quit(0)


#------------------------------------------------------------------------------------------
# @api benchmark
#------------------------------------------------------------------------------------------
const defaultLineSize = 39


type ProfileItem = object
  totalTime:      int64
  totalBestTimes: int
  nanoseconds:    seq[int64]


type TimeMode* = enum
  sec,
  ms


var profiles = initTable[string,ProfileItem]()
var benchSteps: int


proc updateBestResult() =
  ## Score a profile with smallest time footprint.
  var minResult = high(int64)
  var profile: ptr ProfileItem
  for key, val in mpairs(profiles):
    if val.totalTime < minResult: 
      minResult = val.totalTime
      profile   = val.addr
  inc profile.totalBestTimes


proc showBestResult(totalSteps: int) =
  proc printBestRuns(score: int, runs: int): string =
    let s = (float)score
    let r = (float)runs
    result = " (" & formatFloat(s / r * 100f, format = ffDecimal, precision = 1) & "% " & &"of {runs} runs)"
  if profiles.len <= 1: 
    return
  #
  var bestScore = -high(int)
  var bestProfileName: string
  var bestProfile:     ptr ProfileItem
  for key, val in mpairs(profiles):
    if bestScore < val.totalBestTimes:
      bestScore       = val.totalBestTimes
      bestProfileName = key
      bestProfile     = val.addr
  var bestResult = ""
  var slowdownResults = ""
  bestResult = "Fastest: " & bestProfileName & printBestRuns(bestScore, totalSteps)
  #
  for key, value in mpairs(profiles):
    let resultSlowdown = formatFloat(value.totalTime / bestProfile.totalTime, format = ffDecimal, precision = 2)
    slowdownResults.add(" " & key & " " & repeat('.',defaultLineSize - key.len - resultSlowdown.len - 1) & align("x" & $resultSlowdown, 5) & "\n")
  ln "[name] ....................... [slowdown]"
  ln slowdownResults
  ln bestResult & "\n" & repeat('-',bestResult.len)


proc showResults(totalSteps: int, benchMode: TimeMode) =
  var timeTotalTag = "sec "
  proc getTimeTotal(item: var ProfileItem): float64 = 
    if benchMode == TimeMode.sec:
      result = item.totalTime / 1000000000
    else:
      result = item.totalTime / 1000000
      timeTotalTag = "ms "
  proc getTimeMinMs(item: var ProfileItem): float64 = min(item.nanoseconds)/1000000
  proc getTimeAvgMs(item: var ProfileItem): float64 = (item.totalTime/totalSteps) / 1000000
  proc getTimeMaxMs(item: var ProfileItem): float64 = max(item.nanoseconds)/1000000
  var results = ""
  var label   = "[name] ....................... [total time]     [min time]     [avg time]     [max time]     [runs]"
  for key, value in mpairs(profiles):
    let timeTotal = formatFloat(getTimeTotal(value), format = ffDecimal, precision = 6)
    let timeMinMs = formatFloat(getTimeMinMs(value), format = ffDecimal, precision = 5)
    let timeAvgMs = formatFloat(getTimeAvgMs(value), format = ffDecimal, precision = 5)
    let timeMaxMs = formatFloat(getTimeMaxMs(value), format = ffDecimal, precision = 5)
    let stats     = timeTotal & timeTotalTag & 
    align(timeMinMs, 12)  & "ms " & 
    align(timeAvgMs, 12)  & "ms " & 
    align(timeMaxMs, 12)  & "ms " & 
    align("x" & $totalSteps, 10)
    results.add(" " & key & " " & repeat('.',defaultLineSize - key.len - timeTotal.len) & " " & stats & "\n")
  ln label
  ln results
  showBestResult(totalSteps)


proc getNS(): int64 =
  getMonoTime().ticks


template profile*(tag: string, code: untyped) =
  var t1 = 0
  var t2 = 0
  block:
    if not profiles.haskey(tag):
      profiles[tag] = ProfileItem()
    let item = profiles[tag].addr
    var benchIndex {.inject.} = 0
    t1 = getNS()
    while benchIndex < benchSteps:
      code
      inc benchIndex
    t2 = getNS()
    let delta = t2-t1
    item.totalTime += delta
    item.nanoseconds.add(delta)


template benchmark*(steps: int, iterations: int, benchMode: TimeMode, code: untyped) =
  profiles   = initTable[string,ProfileItem]()
  benchSteps = steps
  ln "Benchmark:"
  block:
    for i in 0..<iterations:
      code
      updateBestResult()
    showResults(iterations, benchMode)


template benchmark*(steps: int, iterations: int, code: untyped) =
  benchmark(steps, iterations, sec, code)
#------------------------------------------------------------------------------------------
# @api errors
#------------------------------------------------------------------------------------------
proc fatal*(api: DebugAPI, message: string) =
  pxd.debug.error(message, 1)
  pxd.debug.terminateApp()


proc fatal*(api: DebugAPI, errotType: string, message: string) =
  var composedMessage: string
  composedMessage.add(&"[{errotType}] ")
  composedMessage.add(message)
  pxd.debug.error(composedMessage, 1)
  pxd.debug.terminateApp()


proc fatal*(api: DebugAPI, errotType: string, message: string, traceCutSteps: int) =
  var composedMessage: string
  composedMessage.add(&"[{errotType}] ")
  composedMessage.add(message)
  pxd.debug.error(composedMessage, 1 + traceCutSteps)
  pxd.debug.terminateApp()


#------------------------------------------------------------------------------------------
# @api assertions
#------------------------------------------------------------------------------------------
template assert*(api: DebugAPI, source: untyped) =
  when defined(debug):
    block:
      let tag  {.inject.} = source[1]
      let desc {.inject.} = source[2]
      if not source[0]:
        pxd.debug.error(&"[{tag}] {desc}",1)


template requireMessage*(pmessage: string, pfileName: string, pprocName: string): string =
  when defined(debug):
    pmessage
  else:
    block:
      let message  {.inject.} = pmessage
      let filename {.inject.} = pfileName
      let procname {.inject.} = pprocName
      &"{message}\n⯈ {filename} {procname}"


pxd.debug.init()