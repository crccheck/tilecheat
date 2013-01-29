// Generated by CoffeeScript 1.4.0
(function() {
  var bestMatchSort, difference, findNeighbor, getEdgeData, getPixel, main, n_slices, normalizeResultGrid, setPixel, slice_w, width,
    __hasProp = {}.hasOwnProperty;

  n_slices = 4;

  slice_w = 0;

  width = 0;

  getPixel = function(d, x, y) {
    var index, rgba;
    index = (x + y * width) * 4;
    rgba = [d[index], d[index + 1], d[index + 2], d[index + 3]];
    return rgba[1];
  };

  setPixel = function(d, x, y) {
    var index, rgba;
    index = (x + y * width) * 4;
    rgba = [d[index], d[index + 1], d[index + 2], d[index + 3]];
    d[index] = 0;
    d[index + 1] = 0;
    d[index + 2] = 0;
    return d;
  };

  getEdgeData = function(d, m, n) {
    var data, i, j, x_begin, x_end, y_begin, y_end, _i, _j;
    x_begin = m * slice_w;
    x_end = x_begin + slice_w - 1;
    y_begin = n * slice_w;
    y_end = y_begin + slice_w - 1;
    data = {
      id: "" + m + "." + n,
      grid: {
        m: m,
        n: n
      },
      n: [],
      s: [],
      e: [],
      w: []
    };
    for (i = _i = x_begin; x_begin <= x_end ? _i <= x_end : _i >= x_end; i = x_begin <= x_end ? ++_i : --_i) {
      data.n.push(getPixel(d, i, y_begin));
      data.s.push(getPixel(d, i, y_end));
    }
    for (j = _j = y_begin; y_begin <= y_end ? _j <= y_end : _j >= y_end; j = y_begin <= y_end ? ++_j : --_j) {
      data.e.push(getPixel(d, x_begin, j));
      data.w.push(getPixel(d, x_end, j));
    }
    return data;
  };

  difference = function(d1, d2) {
    var i, sum, value, _i, _len;
    sum = 0;
    for (i = _i = 0, _len = d1.length; _i < _len; i = ++_i) {
      value = d1[i];
      sum += Math.abs(d2[i] - value);
    }
    return sum;
  };

  bestMatchSort = function(a, b) {
    return a[0] - b[0];
  };

  findNeighbor = function(start, edgeData) {
    var allMatches, bestMatch, currentMatches, data, _i, _j, _k, _l, _len, _len1, _len2, _len3;
    allMatches = [];
    currentMatches = [];
    for (_i = 0, _len = edgeData.length; _i < _len; _i++) {
      data = edgeData[_i];
      currentMatches.push([difference(start.n, data.s), data.id, "n"]);
    }
    allMatches.push(currentMatches.sort(bestMatchSort)[0]);
    currentMatches = [];
    for (_j = 0, _len1 = edgeData.length; _j < _len1; _j++) {
      data = edgeData[_j];
      currentMatches.push([difference(start.s, data.n), data.id, "s"]);
    }
    allMatches.push(currentMatches.sort(bestMatchSort)[0]);
    currentMatches = [];
    for (_k = 0, _len2 = edgeData.length; _k < _len2; _k++) {
      data = edgeData[_k];
      currentMatches.push([difference(start.e, data.w), data.id, "e"]);
    }
    allMatches.push(currentMatches.sort(bestMatchSort)[0]);
    currentMatches = [];
    for (_l = 0, _len3 = edgeData.length; _l < _len3; _l++) {
      data = edgeData[_l];
      currentMatches.push([difference(start.w, data.e), data.id, "w"]);
    }
    allMatches.push(currentMatches.sort(bestMatchSort)[0]);
    return bestMatch = allMatches.sort(bestMatchSort)[0];
  };

  normalizeResultGrid = function(input) {
    var bits, key, minX, minY, newObj, value;
    minX = 99;
    minY = 99;
    for (key in input) {
      if (!__hasProp.call(input, key)) continue;
      bits = key.split('.');
      minX = Math.min(minX, bits[0]);
      minY = Math.min(minY, bits[1]);
    }
    newObj = {};
    for (key in input) {
      if (!__hasProp.call(input, key)) continue;
      value = input[key];
      bits = key.split('.');
      newObj["" + (bits[0] - minX) + "." + (bits[1] - minY)] = value;
    }
    return newObj;
  };

  main = function() {
    var attempts, bits, c, canvas, col, dBits, dTile, edgeData, i, imageData, img, mapping, neighbor, newEdgeData, num, placedTiles, positionX, positionY, resultGrid, reverseResultGrid, row, sBits, sTile, slices, start, threshold, x, _i, _j, _len, _len1, _results;
    img = $('img')[0];
    width = img.width;
    slice_w = width / n_slices;
    canvas = $('canvas')[0];
    c = canvas.getContext("2d");
    c.drawImage(img, 0, 0, 240, 240);
    imageData = c.getImageData(0, 0, canvas.width, canvas.height);
    edgeData = [];
    slices = new Array(n_slices * n_slices);
    for (i = _i = 0, _len = slices.length; _i < _len; i = ++_i) {
      num = slices[i];
      row = Math.floor(i / n_slices);
      col = i % n_slices;
      edgeData.push(getEdgeData(imageData.data, row, col));
    }
    resultGrid = {};
    reverseResultGrid = {};
    start = edgeData.pop();
    positionX = 0;
    positionY = 0;
    resultGrid["" + positionX + "." + positionY] = start.id;
    reverseResultGrid[start.id] = "" + positionX + "." + positionY;
    placedTiles = [start];
    threshold = 1000;
    while (edgeData.length) {
      console.log("Iteration Start", placedTiles.length);
      attempts = 15;
      neighbor = null;
      while ((neighbor = findNeighbor(start, edgeData, threshold))[0] > threshold) {
        console.log("no neighbor meeting threshold found, pick a new start", neighbor);
        start = placedTiles[Math.floor(Math.random() * placedTiles.length)];
        bits = reverseResultGrid[start.id].split('.');
        positionX = bits[0];
        positionY = bits[1];
        if (!--attempts) {
          attempts = 15;
          threshold = threshold * 1.1;
          console.log("Raising threshold: " + threshold);
        }
        if (threshold > 100000) {
          console.error("oops", findNeighbor(start, edgeData, threshold));
          return;
        }
      }
      console.log("Neighbor found", neighbor);
      newEdgeData = [];
      for (_j = 0, _len1 = edgeData.length; _j < _len1; _j++) {
        x = edgeData[_j];
        if (x.id === neighbor[1]) {
          start = x;
          placedTiles.push(x);
        } else {
          newEdgeData.push(x);
        }
      }
      switch (neighbor[2]) {
        case "n":
          positionY--;
          break;
        case "s":
          positionY++;
          break;
        case "e":
          positionX++;
          break;
        case "w":
          positionX--;
      }
      if (!resultGrid["" + positionX + "." + positionY]) {
        edgeData = newEdgeData;
        resultGrid["" + positionX + "." + positionY] = neighbor[1];
        reverseResultGrid[neighbor[1]] = "" + positionX + "." + positionY;
      }
    }
    mapping = normalizeResultGrid(resultGrid);
    c.clearRect(0, 0, canvas.width, canvas.height);
    _results = [];
    for (dTile in mapping) {
      if (!__hasProp.call(mapping, dTile)) continue;
      sTile = mapping[dTile];
      sBits = sTile.split('.');
      dBits = dTile.split('.');
      _results.push(c.drawImage(img, sBits[0] * slice_w, sBits[1] * slice_w, slice_w, slice_w, dBits[0] * slice_w, dBits[1] * slice_w, slice_w, slice_w));
    }
    return _results;
  };

  $(window).load(function() {
    return main();
  });

}).call(this);
