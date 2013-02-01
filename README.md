Takes a square image that's been divided into N x N tiles and then scrambled and
attempts to discover the original image.


##Notes

* I think the edge matching can be greatly improved the slice width is a
  [multiple of 8]. I haven't tried it yet.
* Source images that are heavily vignetted/edged (Instagram) are difficult to
  unscramble because the algorithm naturally sees those edges as very clean
  seams. For now, I'm combating this by artificially adding noise to very dark
  pixels. But in the future, it would be nice to prioritize complicated edges
  over simple edges.
* I made up the algorithms to unscramble the images myself as a thought
  exercise. There are definitely better ones out there. I couldn't find any that
  looked easy to port to CoffeeScript in a cursory search. I did have another
  idea that was basicaly a lot like calculating a determinate of a matrix but I
  haven't gotten around to writing it yet.


##Development

Run `make dev`. If you need to do something else, inspect the [Makefile].
Unfortunately, the source is CoffeeScript because I wanted this to run in a
browser and I find it much easier to experiment in CoffeeScript over JavaScript.


##Demo

[Live Demo]


[multiple of 8]: https://en.wikipedia.org/wiki/JPEG#Discrete_cosine_transform
[Makefile]: https://github.com/crccheck/tilecheat/blob/master/Makefile
[Live Demo]: http://crccheck.github.com/tilecheat/

