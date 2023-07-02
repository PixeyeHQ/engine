proc mergeSort*[T](data: var seq[T], len: int, compare: proc(a,b:T):int) {.inline.}=
  proc merge(data: var seq[T], left: int, mid: int, right: int) =
    var merged: seq[T] = newSeq[T](right - left + 1)
    var leftIndex   = left
    var rightIndex  = mid + 1
    var mergedIndex = 0

    while leftIndex <= mid and rightIndex <= right:
      if compare(data[leftIndex], data[rightIndex]) <= 0:
        merged[mergedIndex] = data[leftIndex]
        inc(leftIndex)
      else:
        merged[mergedIndex] = data[rightIndex]
        inc(rightIndex)
      inc(mergedIndex)

    while leftIndex <= mid:
      merged[mergedIndex] = data[leftIndex]
      inc(leftIndex)
      inc(mergedIndex)

    while rightIndex <= right:
      merged[mergedIndex] = data[rightIndex]
      inc(rightIndex)
      inc(mergedIndex)

    for i in 0 ..< merged.len:
      data[left + i] = merged[i]

  proc mergeSortImpl(data: var seq[T], left: int, right: int) =
    if left < right:
      var mid = (left + right) div 2
      mergeSortImpl(data, left, mid)
      mergeSortImpl(data, mid + 1, right)
      merge(data, left, mid, right)
  
  mergeSortImpl(data, 0, len-1)


proc mergeSort*[T](data: var seq[T], compare: proc(a,b:T):int) {.inline.}=
  mergeSort(data,data.len,compare)