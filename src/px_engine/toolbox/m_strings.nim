proc trim*(self: string, x: char): string =
  result = newStringOfCap(self.len)
  for character in self:
    if character == x:
      continue
    else:
      result.add(character)