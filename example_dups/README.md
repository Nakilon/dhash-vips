# Image duplicates search demo

https://hub.docker.com/repository/docker/nakilonishe/dhash-vips-demo

This is a sample Docker image that you can use to find duplicates in a folder you link.  
So you don't need Ruby or even git to try the gem, just Docker:

![](https://storage.googleapis.com/dhash-vips.nakilon.pro/example_dups.png)

```none
$ docker run --rm -v $(pwd)/good:/images nakilonishe/dhash-vips-demo

["*.jp*g", "*.png"] images found: 6

very similar image pairs: 1

  distance: 11
  Eiffel_Tower,_view_from_the_Trocadero,_1_July_2008.jpg
  Eiffelturm.jpeg

similar image pairs: 1

  distance: 18
  Aha_waah_taz.jpg
  Beauty_of_Taj_Mahal_can_only_felt_by_heart.jpg

probably similar image pairs: 3

  distance: 20
  Beauty_of_Taj_Mahal_can_only_felt_by_heart.jpg
  Like_A_Pearl_(60650624).jpeg

  distance: 21
  Eiffel_Tower,_November_15,_2011.jpg
  Eiffel_Tower,_view_from_the_Trocadero,_1_July_2008.jpg

  distance: 22
  Eiffel_Tower,_November_15,_2011.jpg
  Eiffelturm.jpeg
```

Here thresholds are hardcoded as `[0..14, 15..19, 20..24]`. They are a bit lowered and adjusted for demo purposes -- all landscapes are a bit similar because they have a horizon line.  
In your programs you should find the best fitting thresholds and maybe preprocess images by smart cropping, applying filters, etc.

Maybe some day I'll make it a feature (with JSON and HTML export) within a gem if anyone needs it.

P.S.: don't forget that Docker `-v` needs an absolute path. And you can link it as `:ro` (read-only) if you want. The script does not write anything.
