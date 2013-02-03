# attempt 2.
#
# This solver find the best possible matching pair, and then finds the the next
# tile that best matches an already placed tile until it runs out of tiles.

#
getResult2 = (tiles)->
  # Build map of every edge distance possible.
  #
  # I think this is O(4n^2!), which doesn't sound very efficient, but a 16x16
  # grid only makes 480 entries. There will be 4 * C(n^2, 2) entries, so 10
  # slices per side will make 4950 entries. Keys are
  # `<tile><orientation><tile>`, where orientation is (v)ertical or
  # (h)orizontal. If this were a typed language, I could probably save some
  # memory and eke out some performance by making distance an integer.
  delay = _options.draw_delay
  buildMap = ->
    map = {}
    for tile1, i in tiles
      for tile2 in tiles[(i + 1)..]
        map["#{tile1.id}h#{tile2.id}"] = distance(tile1.w, tile2.e)
        map["#{tile2.id}h#{tile1.id}"] = distance(tile2.w, tile1.e)
        map["#{tile1.id}v#{tile2.id}"] = distance(tile1.s, tile2.n)
        map["#{tile2.id}v#{tile1.id}"] = distance(tile2.s, tile1.n)
    return map
  window.map = map = buildMap()

  # Get the resulting coordinate moving N/S/E/W from an existing coordinate.
  window.move = move = (coord, direction) ->
    bits = String(coord).split('.')
    switch direction
      when "n" then --bits[1]
      when "s" then ++bits[1]
      when "e" then ++bits[0]
      when "w" then --bits[0]
    return bits.join('.')

  # Build the converse of the `reverseGrid` so we can look up where a tile was
  # placed. Not very efficient than the code I used to have, but made things
  # more readable. Somewhere a garbage collector is crying.
  buildReverseResultGrid = (input) ->
    output = {}
    for own key, value of input
      output[value] = key
    return output

  resultGrid = {}
  reverseResultGrid = {}
  placedTiles = []

  _inner_iteration_count = 0
  _inner = ->
    # Find the closest match. As more tiles get placed, the regular expression
    # gets more complex, and the first time through the loop, it is unnecessary.
    # It is important to this algorithm that we only find matches to already
    # places tiles because trying to handle simultanous disjoint sets would
    # suuuuuuuck.
    matchDistance = 9999
    match = ""
    mapFilterRe = new RegExp("(#{placedTiles.join(")|(")})".replace(/\./g, "\\."))
    for own testMatch, testMatchDistance of map
      if mapFilterRe.test(testMatch) and testMatchDistance < matchDistance
        matchDistance = testMatchDistance
        match = testMatch
    console.log "step #{++_inner_iteration_count} match:", match

    # Place the matching tile, `match` (two tiles the first time).
    matchPair = match.split(/[vh]/)
    matchPairOrientation = if match.indexOf('v') != -1 then "v" else "h"
    if !placedTiles.length  # this is our first time through the loop
      origin = '0.0'
      resultGrid[origin] = matchPair[0]
      reverseResultGrid = buildReverseResultGrid(resultGrid)
    console.log "map.length", Object.getOwnPropertyNames(map).length
    a = matchPair[0]
    b = matchPair[1]
    if origin = reverseResultGrid[a]
      toBePlaced = b
      if matchPairOrientation == "v"
        resultGrid[move(origin, "s")] = b
      else
        resultGrid[move(origin, "e")] = b
    else if origin = reverseResultGrid[b]
      toBePlaced = a
      if matchPairOrientation == "v"
        resultGrid[move(origin, "n")] = a
      else
        resultGrid[move(origin, "w")] = a
    else
      console.error "oops, incorrectly matched a disjoint tile"
      return resultGrid

    # Cleanup and setup for the next run through the loop.

    #
    window.resultGrid = resultGrid
    window.reverseResultGrid = reverseResultGrid = buildReverseResultGrid(resultGrid)
    placedTiles = Object.keys(reverseResultGrid)
    # Eliminate all invalid matches.
    for own key, value of map
      if key.startsWith("#{a}#{matchPairOrientation}")
        delete map[key]
        continue
      if key.endsWith("#{matchPairOrientation}#{b}")
        delete map[key]
        continue
      matchPair = key.split(/[vh]/)
      # remove already placed tiles
      if matchPair[0] in placedTiles and matchPair[1] in placedTiles
        delete map[key]
        continue
    # Check the other orientation of `toBePlaced`.
    # TODO this block could be executed smarter
    if resultGrid[move(reverseResultGrid[toBePlaced], "e")]
      console.log "!!!Delete east of #{toBePlaced}"
      for own key, value of map
        if key.startsWith("#{toBePlaced}h")
          delete map[key]
          continue
    if resultGrid[move(reverseResultGrid[toBePlaced], "s")]
      console.log "!!!Delete south of #{toBePlaced}"
      for own key, value of map
        if key.startsWith("#{toBePlaced}v")
          delete map[key]
          continue
    if resultGrid[move(reverseResultGrid[toBePlaced], "n")]
      console.log "!!!Delete north of #{toBePlaced}"
      for own key, value of map
        if key.endsWith("v#{toBePlaced}")
          delete map[key]
          continue
    if resultGrid[move(reverseResultGrid[toBePlaced], "w")]
      console.log "!!!Delete west of #{toBePlaced}"
      for own key, value of map
        if key.endsWith("h#{toBePlaced}")
          delete map[key]
          continue
    console.log "map.length",
                Object.getOwnPropertyNames(map).length,
                copy(map),
    if delay
      drawGrid(resultGrid)  # TODO use pubsub instead of just calling this

  # for stepNumber in [1..11]
  for stepNumber in [1..(n_slices * n_slices - 1)]
    if delay
      setTimeout(_inner, stepNumber * _options.draw_delay)
    else
      _inner()

  return resultGrid
