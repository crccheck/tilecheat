# get a resultGrid based on the edgeData
  # attempt 1, the long, stupid, dirty way
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
