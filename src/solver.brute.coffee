# get a resultGrid based on the edgeData
  # attempt 1, the long, stupid, dirty way


# for Array.sort
bestMatchSort = (a, b) -> a[0] - b[0]


# find the best neighbor for `targetSlice` from `edgeData`
findNeighbor = (targetSlice, edgeData, edges="news")->
  allMatches = []
  if "n" in edges
    # find north match
    currentMatches = []
    for data in edgeData
      currentMatches.push([distance(targetSlice.n, data.s), data.id, "n"])
    allMatches.push(currentMatches.sort(bestMatchSort)[0])
  if "s" in edges
    # find south match
    currentMatches = []
    for data in edgeData
      currentMatches.push([distance(targetSlice.s, data.n), data.id, "s"])
    allMatches.push(currentMatches.sort(bestMatchSort)[0])
  if "e" in edges
    # find east match
    currentMatches = []
    for data in edgeData
      currentMatches.push([distance(targetSlice.e, data.w), data.id, "e"])
    allMatches.push(currentMatches.sort(bestMatchSort)[0])
  if "w" in edges
    # find west match
    currentMatches = []
    for data in edgeData
      currentMatches.push([distance(targetSlice.w, data.e), data.id, "w"])
    allMatches.push(currentMatches.sort(bestMatchSort)[0])

  bestMatch = allMatches.sort(bestMatchSort)[0]


# return empty sides
#
# if a tile already has blocks above and below, return "ew" so findneighber
# knows not to look north or south.
window.validEdge = validEdges = (startCoord, resultGrid) ->
  bits = startCoord.split('.')
  x = +bits[0]
  y = +bits[1]
  edges = ""
  if !resultGrid["#{x}.#{y-1}"]
    edges += "n"
  if !resultGrid["#{x}.#{y+1}"]
    edges += "s"
  if !resultGrid["#{x-1}.#{y}"]
    edges += "e"
  if !resultGrid["#{x+1}.#{y}"]
    edges += "w"
  return edges


getResult = (edgeData)->
  # pick a starting tile
  start = edgeData[Math.floor(Math.random() * edgeData.length)]
  edgeData = (x for x in edgeData when x != start)

  # hold the result
  resultGrid = {}
  reverseResultGrid = {}
  positionX = 0
  positionY = 0
  resultGrid["#{positionX}.#{positionY}"] = start.id
  reverseResultGrid[start.id] = "#{positionX}.#{positionY}"
  placedTiles = [start]

  window.resultGrid = resultGrid  # debug
  window.reverseResultGrid = reverseResultGrid  # debug
  window.placedTiles = placedTiles  # debug

  threshold = 500  # match threshold, distance between edges should be under this
  giveUpThreshold = 50  # give up after this many iterations

  while edgeData.length and (giveUpThreshold-- > 0)
    # console.log "Iteration Start", placedTiles.length, giveUpThreshold
    attempts = 15
    neighbor = null
    # console.log "Looking for neighbor for scrambled #{start.id} in directions #{validEdges(reverseResultGrid[start.id], resultGrid)}"
    neighbor = findNeighbor(start, edgeData, validEdges(reverseResultGrid[start.id], resultGrid))
    # while (neighbor = findNeighbor(start, edgeData, validEdges(reverseResultGrid[start.id], resultGrid)))[0] > threshold
    #   # no neighbor meeting threshold found, pick a new start
    #   console.log "no neighbor meeting threshold found, pick a new start", neighbor
    #   start = placedTiles[Math.floor(Math.random() * placedTiles.length)]
    #   bits = reverseResultGrid[start.id].split('.')
    #   positionX = bits[0]
    #   positionY = bits[1]
    #   if !--attempts
    #     attempts = 15
    #     threshold = threshold * 1.1
    #     console.log "Raising threshold: #{threshold}"
    #   if threshold > 100000
    #     console.error "oops, threshold reached"
    #     return
    # console.log "Neighbor found", neighbor
    newEdgeData = []
    for x in edgeData
      if x.id == neighbor[1]
        start = x
        placedTiles.push x
      else
        newEdgeData.push x
    switch neighbor[2]
      when "n" then positionY--
      when "s" then positionY++
      when "e" then positionX--
      when "w" then positionX++
    solvedCoord = "#{positionX}.#{positionY}"
    if !resultGrid[solvedCoord]
      edgeData = newEdgeData
      resultGrid[solvedCoord] = neighbor[1]
      reverseResultGrid[neighbor[1]] = solvedCoord
    else
      console.error "oops, solved #{solvedCoord} is already taken by #{resultGrid[solvedCoord]}"
      giveUpThreshold = -1  # give up

  # console.log "finished with #{edgeData.length} left and #{giveUpThreshold}"

  return resultGrid
