import std/[tables, strformat, strutils, times, monotimes]
export strformat.`&`
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
  echo "[name] ....................... [slowdown]"
  echo slowdownResults
  echo bestResult & "\n" & repeat('-',bestResult.len)


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
  echo label
  echo results
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
  echo "Benchmark:"
  block:
    for i in 0..<iterations:
      code
      updateBestResult()
    showResults(iterations, benchMode)


template benchmark*(steps: int, iterations: int, code: untyped) =
  benchmark(steps, iterations, ms, code)