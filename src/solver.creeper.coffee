# attempt 2
getResult2 = (tiles)->
  # build map of every edge distance possible.
  #
  # I think this is O(4n!) keys are <tile><orientation><tile>, where orientation
  # is (v)ertical or (h)orizontal
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

  window.move = move = (coord, direction) ->
    bits = String(coord).split('.')
    switch direction
      when "n" then --bits[1]
      when "s" then ++bits[1]
      when "e" then ++bits[0]
      when "w" then --bits[0]
    return bits.join('.')

  # less efficient, but more readable
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
    # find the closest match
    matchDistance = 9999
    match = ""
    mapFilterRe = new RegExp("(#{placedTiles.join(")|(")})".replace(/\./g, "\\."))
    for own testMatch, testMatchDistance of map
      if mapFilterRe.test(testMatch) and testMatchDistance < matchDistance
        matchDistance = testMatchDistance
        match = testMatch
    console.log "step #{++_inner_iteration_count} match:", match

    # place matching tile(s)
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

    # cleanup and setup for the next run through the loop
    window.resultGrid = resultGrid
    window.reverseResultGrid = reverseResultGrid = buildReverseResultGrid(resultGrid)
    placedTiles = Object.keys(reverseResultGrid)
    # eliminate all invalid matches
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
    # check the other orientation of `toBePlaced`
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
    drawGrid(resultGrid)

  # for stepNumber in [1..11]
  for stepNumber in [1..(n_slices * n_slices - 1)]
    setTimeout(_inner, stepNumber * _options.draw_delay)



  return resultGrid
