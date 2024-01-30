import std/[hashes,macros,macrocache,tables,strutils]
import m_debug
import api


const mcIndexMap = CacheTable"indexKeys"


type IndexKey* = object
  value*: int


proc hash*(key: IndexKey): Hash {.inline.} =
  result = hash(key.value)


proc `==`*(a: IndexKey, b: IndexKey): bool {.inline.} =
  return a.value == b.value


converter toOrd*(t: IndexKey): int =
  t.value


var keyIndex : int
var keyIndexMap = initTable[string,IndexKey]()

 
proc Next*(): IndexKey  =
  result = IndexKey(value: keyIndex)
  inc keyIndex


proc Next*(value: int): IndexKey =
  keyIndex = value
  result = IndexKey(value: keyIndex)
  inc keyIndex


proc Next*(name: string): IndexKey =
  if keyIndexMap.contains(name):
    return  keyIndexMap[name]
  result = IndexKey(value: keyIndex)
  keyIndexMap[name] = result
  inc keyIndex


proc Next*(name: string, value: int) =
  keyIndexMap[name] = IndexKey(value: value)


proc GetKey*(name: string): IndexKey =
  if keyIndexMap.contains(name):
    return  keyIndexMap[name]
  else:
    pxd.debug.warn &"INDEX KEY: Key not found: {name}"


proc CheckKey*(name: string): bool =
  return keyIndexMap.contains(name)


converter toKey*(name: string): IndexKey =
  GetKey(name)


converter toKey*(id: int): IndexKey =
  IndexKey(value: id)


macro genIndexKeys*(api: PxdAPI, args: varargs[untyped]): untyped =
  var apiName  = $args[0]
  var typeName = apiName & "IndexKeys"
  var indices  = newSeq[string]()
  for index in 1..<args.len:
    indices.add($args[index])
  proc genTypeSection(): NimNode =
    let recList = nnkRecList.newTree()
    var i    = 0
    var step = 0
    for index in indices.items:
      let keyName = toLowerAscii(index)
      if mcIndexMap.hasKey(keyName):
        i = mcIndexMap[keyName].intVal
      else:
        mcIndexMap[keyName] = newLit(i)
      recList.add(nnkIdentDefs.newTree(
         nnkPostfix.newTree(
           newIdentNode("*"),
           newIdentNode(indices[step])
         ),
         newIdentNode("IndexKey"),
         nnkObjConstr.newTree(
           newIdentNode("IndexKey"),
           nnkExprColonExpr.newTree(
             newIdentNode("value"),
             newIntLitNode(i)
           )
         )
       )
      )
      inc i
      inc step
    result = nnkTypeSection.newTree(
      nnkTypeDef.newTree(
      nnkPostfix.newTree(
              newIdentNode("*"),
              newIdentNode(typeName)
            ),
        newEmptyNode(),
        nnkObjectTy.newTree(
          newEmptyNode(),
          newEmptyNode(),
          recList
        )
      )
    )
  proc genConstSection(): NimNode =
    result = nnkConstSection.newTree(
      nnkConstDef.newTree(
        nnkPostfix.newTree(
          newIdentNode("*"),
          newIdentNode(apiName)
        ),
        newEmptyNode(),
        nnkCall.newTree(
          newIdentNode(typeName)
        )
      )
    )
  proc genCalls(stm: NimNode) =
    for index in indices.items:
      # all string keys must begin with a small letter.
      let keyName = toLowerAscii(index)
      stm.add(
        nnkCall.newTree(
          newIdentNode("Next"),
          newStrLitNode(keyName),
          newIntLitNode(mcIndexMap[keyName].intVal)
        )
      )
  
  var statement = nnkStmtList.newTree()
  statement.add(genTypeSection())
  statement.add(genConstSection())
  genCalls(statement)
  statement
