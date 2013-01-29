n_slices = 4
slice_w = 0
width = 0

getPixel = (d, x, y) ->
  index = (x + y * width) * 4
  rgba = [d[index], d[index + 1], d[index + 2], d[index + 3]]
  # only use green channel for now
  return rgba[1]

setPixel = (d, x, y) ->
  index = (x + y * width) * 4
  rgba = [d[index], d[index + 1], d[index + 2], d[index + 3]]
  # console.log rgba
  d[index] = 0
  d[index + 1] = 0
  d[index + 2] = 0
  return d

getEdgeData = (d, m, n) ->
  x_begin = m * slice_w
  x_end = x_begin + slice_w - 1
  y_begin = n * slice_w
  y_end = y_begin + slice_w - 1
  data =
    grid:
      m: m
      n: n
    n: []
    s: []
    e: []
    w: []
  for i in [x_begin..x_end]
    data.n.push(getPixel d, i, y_begin)
    data.s.push(getPixel d, i, y_end)
  for j in [y_begin..y_end]
    data.e.push(getPixel d, x_begin, j)
    data.w.push(getPixel d, x_end, j)
  return data


main = ->
  img = $('img')[0]
  width = img.width
  slice_w = width / n_slices

  canvas = $('canvas')[0]
  c = canvas.getContext("2d")
  c.drawImage(img, 0, 0, 240, 240)

  imageData = c.getImageData(0, 0, canvas.width, canvas.height)

  slices = new Array(n_slices * n_slices)
  for num, i in slices
    row = Math.floor(i / n_slices)
    col = i % n_slices
    console.log getEdgeData(imageData.data, row, col)

    # console.log row * slice_w, col * slice_w


  c.putImageData(imageData, 0, 0)


$(window).load(->
  main()
)
