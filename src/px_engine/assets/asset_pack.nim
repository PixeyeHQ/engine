import std/tables
import ../pxd/[api, m_memory, m_debug]
type
  AssetPack* = ref object
    items*: Table[string, Handle]


var assetPacks = initTable[string, AssetPack]()


proc getPack*(api: AssetAPI, packId: string): AssetPack =
  if not assetPacks.hasKey(packId):
    assetPacks[packId] = AssetPack()
  assetPacks[packId]


proc getPack*(api: AssetAPI): AssetPack =
  api.getPack("main")


proc setPack*(api: AssetAPI, packId: string, pack: AssetPack) =
  assetPacks[packId] = pack


proc has*[T](self: AssetPack, relativePath: string, typeof: typedesc[T]): bool =
  let tag = relativePath & $typeof
  self.items.hasKey(tag)


proc get*[T](self: AssetPack, relativePath: string, typeof: typedesc[T]): typeof =
  let tag = relativePath & $typeof
  if not self.items.hasKey(tag):
    pxd.debug.fatal("NO ASSET")
  T(self.items[tag])

