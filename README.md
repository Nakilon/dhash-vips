[![Gem Version](https://badge.fury.io/rb/dhash-vips.svg)](http://badge.fury.io/rb/dhash-vips) [![Docker Image](https://github.com/nakilon/dhash-vips/workflows/Docker%20Image/badge.svg)](https://hub.docker.com/repository/docker/nakilonishe/dhash-vips/general)

# dHash and IDHash gem powered by ruby-vips

The **dHash** is the algorithm of image fingerprinting that can be used to measure the similarity of two images.  
The **IDHash** is the new algorithm that has some improvements over dHash -- I'll describe it further.

You can read about the dHash and perceptual hashing in the article ["Kind of Like That" at "The Hacker Factor Blog"](http://www.hackerfactor.com/blog/index.php?/archives/529-Kind-of-Like-That.html) (21 January 2013). The idea is that you resize the otiginal image to 8x9 and then convert it to 8x8 array of bits -- each tells if the corresponding segment of the image is brighter or darker than the one on the right (or left). Then you apply the [Hamming distance](https://en.wikipedia.org/wiki/Hamming_distance) to such arrays to measure how much they are different.

There were several Ruby implementations on Github already but they all depended on ImageMagick. My implementation takes an advantage of speed of the libvips (the `ruby-vips` gem) -- it fingerprints images much faster:

    load the image and calculate the fingerprint:
                              user     system      total        real
    Dhash                 6.191731   0.230885   6.422616 (  6.428763)
    DHashVips::DHash      0.858045   0.144820   1.002865 (  0.924308)

`Dhash` here is [another gem](https://github.com/maccman/dhash) that I used earlier in my projects before I decided to make this one.  
Unfortunately both gems made slightly different fingerprints for two image files that are supposed to have the same fingerprint because from the human point of view they are the same (photo by Jordan Voth):  
![](https://storage.googleapis.com/dhash-vips.nakilon.pro/dhash_issue_example.png)  
The distance here appeared to be equal to 5. This is why I've decided to improve the algorithm and this is how the "IDHash" appeared.

## IDHash (the Important Difference Hash)

The main improvement over the dHash is what makes it insensitive to the resizing algorithm, color scheme and effectively made the pair of images above to have a distance of 0.

* The "Importance" is an array of extra 64 bits that tells the comparing function which half of 64 bits is important (when the difference between neighbors was enough significant) and which is not. So not every bit in a fingerprint is being compared but only half of them.  
* It subtracts not only horizontally but also vertically -- that adds 128 more bits.  
* Instead of resizing to 8x9 it resizes to 8x8 and puts the image on a torus so it subtracts the very left column from the very right one and the top from the bottom.

You could see in fingerprint calculation benchmark earlier that these improvements didn't make it slower than dHash because most of the time is spent on image resizing. Distance measurement is what became slower.

### Example

Here are two photos (by Brian Lauer):  
![](https://storage.googleapis.com/dhash-vips.nakilon.pro/idhash_example_in.png)  
and visualization of IDHash (`rake compare_images -- image1.jpg image2.jpg`):  
![](https://storage.googleapis.com/dhash-vips.nakilon.pro/idhash_example_out.png)  

Here in each of 64 cells, there are two circles that color the difference between that cell and the neighbor one. If the difference is low the Importance bit is set to zero and the circle is invisible. So there are 128 pairs of corresponding circles and when you take one, if at least one circle is visible and is of different color the line is to be drawn. Here you see 15 lines and so the distance between fingerprints will be equal to 15 (that is pretty low and can be interpreted as "images look similar"). Also, you see here that floor on this photo matters -- classic dHash won't see that it's darker than wall because it's comparing only horizontal neighbors and if one photo had no floor the distance function won't notice that. Also, it sees the Important difference between the very right and left columns because the wall has a slow but visible gradient.

### Remaining problems

* Neither dHash nor IDHash can't automatically detect very shifted crops and rotated images but you can make a wrapper that would call the comparison function iteratively.  
* These algorithms are color blind because of converting an image to grayscale. If you take a photo of something in your yard the sun will create lights and shadows, but if you compare photos of something green painted on a blue wall there is a possibility the machine would see nothing painted at all. The `dhash` gem had such image in specs and that made them pretty useless (this was supposed to be a face):  
![](https://storage.googleapis.com/dhash-vips.nakilon.pro/colorblind.png)  
* If you have a pile of 1000000 images comparing them with each other would take a month or two. To improve the process in case of dHash that uses Hamming distance you may want to read these threads on Stackexchange network:  
  * [How to find the closest pairs of a string of binary bins in Ruby without O^2 issues?](https://stackoverflow.com/q/8734034/322020)  
  * [Find all pairs of values that are close under Hamming distance](https://cstheory.stackexchange.com/q/18516/27420)  
  * [Finding the closest pair between two sets of points on the hypercube](https://cstheory.stackexchange.com/q/16322/27420)  
  * [Would PCA work for boolean data types?](https://stats.stackexchange.com/q/159705/1125)  
  * [Using pHash to search agaist a huge image database, what is the best approach?](https://stackoverflow.com/q/18257641/322020)  

## Installation

    brew install vips

If you have troubles, see https://jcupitt.github.io/libvips/install.html  
Then:

    gem install dhash-vips

If you have troubles with the `gem ruby-vips` dependency, see https://github.com/libvips/ruby-vips

## Usage

### dHash:

```ruby
require "dhash-vips"

hash1 = DHashVips::DHash.calculate "photo1.jpg"
hash2 = DHashVips::DHash.calculate "photo2.jpg"

distance = DHashVips::DHash.hamming hash1, hash2
if distance < 10
  puts "Images are very similar"
elsif distance < 20
  puts "Images are slightly similar"
else
  puts "Images are different"
end
```

### IDHash:

```ruby
require "dhash-vips"

hash1 = DHashVips::IDHash.fingerprint "photo1.jpg"
hash2 = DHashVips::IDHash.fingerprint "photo2.jpg"

distance = DHashVips::IDHash.distance hash1, hash2
if distance < 15
  puts "Images are very similar"
elsif distance < 25
  puts "Images are slightly similar"
else
  puts "Images are different"
end
```

### Notes and benchmarks

* The above `15` and `25` constants are found empirically and just work enough well for 8-byte hashes. To find these thresholds we can run a rake task with hardcoded test cases (pairs of photos from the same photosession are not the same but are considered to be enough 'similar' for the purpose of this benchmark):

      $ rake compare_quality

                            Dhash  Phamilie  DHashVips::DHash  DHashVips::IDHash  DHashVips::IDHash(4) 
          The same image:    0..0      0..0              0..0               0..0                  0..0 
      'Jordan Voth case':       4         2                 4                  0                     0 
          Similar images:   1..17    14..34             2..23              6..22               53..166 
        Different images:   9..57    22..42             9..50             18..65              120..233 
                1/FMI^2 =    1.25       4.0             1.556               1.25                 1.306 
                 FP, FN =  [2, 0]    [0, 6]            [1, 2]             [2, 0]                [1, 1] 

    The `FMI` line here is the "quality of algorithm", i.e. the best achievable function from the ["Fowlkes–Mallows index"](https://en.wikipedia.org/wiki/Fowlkes%E2%80%93Mallows_index) value if you take the "similar" and "different" test pairs and try to draw the threshold line. Smaller number is better. Here I've added the [`phamilie` gem](https://github.com/toy/phamilie) that is DCT based (not a kind of dhash). The last line shows number of false positives (`FP`) and false negatives (`FN`) in case of the best achieved FMI.

* Methods were renamed from `#calculate` to `#fingerprint` and from `#hamming` to `#distance`.  
* The `DHash#calculate` accepts `hash_size` optional parameter that is 8 by default. The `IDHash#fingerprint`'s optional parameter is called `power` and works in a bit different way: 3 means 8 and 4 means 16 -- other sizes are not supported because they don't seem to be useful (higher fingerprint resolution makes it vulnerable to image shifts and croppings, also `#distance` becomes much slower). Because IDHash's fingerprint is more complex than DHash's one it's not that straight forward to compare them so under the hood the `#distance` method have to check the size of fingerprint. If you are sure that fingerprints were made with power=3 then to skip the check you may use the `#distance3` method directly.  
* The `#distance3` method will use Ruby C extension that is around 15 times faster than pure Ruby implementation -- native extension is currently hardcoded to be compiled only if it's macOS and rbenv Ruby 2.3.8 installed with `-k` flag but if you know how to make the gem gracefully fallback to native Ruby if `make` fails let me know or make a pull request. So the full benchmark:

  * Ruby 2.0.0

        $ bundle exec rake compare_speed

        load the image and calculate the fingerprint:
                                  user     system      total        real
        Dhash                12.400000   0.820000  13.220000 ( 13.329952)
        DHashVips::DHash      1.330000   0.230000   1.560000 (  1.509826)
        DHashVips::IDHash     1.060000   0.090000   1.150000 (  1.100332)
        DHashVips::IDHash 4   1.030000   0.080000   1.110000 (  1.089148)

        measure the distance (1000 times):
                                            user     system      total        real
        Dhash hamming                   3.140000   0.020000   3.160000 (  3.179392)
        DHashVips::DHash hamming        3.040000   0.020000   3.060000 (  3.095190)
        DHashVips::IDHash distance      8.170000   0.040000   8.210000 (  8.279950)
        DHashVips::IDHash distance3     6.720000   0.030000   6.750000 (  6.790900)
        DHashVips::IDHash distance 4   24.430000   0.130000  24.560000 ( 24.652625)

  * Ruby 2.3.3 seems to have some bit arithmetics improvement compared to 2.0:

        load the image and calculate the fingerprint:
                                  user     system      total        real
        Dhash                13.110000   0.950000  14.060000 ( 14.537057)
        DHashVips::DHash      1.480000   0.310000   1.790000 (  1.808787)
        DHashVips::IDHash     1.080000   0.100000   1.180000 (  1.156446)
        DHashVips::IDHash 4   1.030000   0.090000   1.120000 (  1.076117)

        measure the distance (1000 times):
                                            user     system      total        real
        Dhash hamming                   1.770000   0.010000   1.780000 (  1.815612)
        DHashVips::DHash hamming        1.810000   0.010000   1.820000 (  1.875666)
        DHashVips::IDHash distance      4.250000   0.020000   4.270000 (  4.350071)
        DHashVips::IDHash distance3     3.430000   0.020000   3.450000 (  3.499031)
        DHashVips::IDHash distance 4    8.210000   0.110000   8.320000 (  8.510735)

  * Ruby 2.3.8p459 (2.4.6, 2.5.5 and 2.6.3 are all similar) with newer CPU (`sysctl -n machdep.cpu.brand_string #=> Intel(R) Core(TM) i5-7360U CPU @ 2.30GHz`):

        load the image and calculate the fingerprint:
                                  user     system      total        real
        Dhash                 6.191731   0.230885   6.422616 (  6.428763)
        Phamilie              5.361751   0.037524   5.399275 (  5.402553)
        DHashVips::DHash      0.858045   0.144820   1.002865 (  0.924308)
        DHashVips::IDHash     0.769975   0.071087   0.841062 (  0.790470)
        DHashVips::IDHash 4   0.805311   0.077918   0.883229 (  0.825897)

        measure the distance (2000 times):
                                               user     system      total        real
        Dhash hamming                      1.810000   0.000000   1.810000 (  1.824719)
        Phamilie distance                  1.000000   0.010000   1.010000 (  1.006127)
        DHashVips::DHash hamming           1.810000   0.000000   1.810000 (  1.817415)
        DHashVips::IDHash distance         1.400000   0.000000   1.400000 (  1.401333)
        DHashVips::IDHash distance3_ruby   3.320000   0.010000   3.330000 (  3.337920)
        DHashVips::IDHash distance3_c      0.210000   0.000000   0.210000 (  0.212864)
        DHashVips::IDHash distance 4       8.300000   0.120000   8.420000 (  8.499735)

* Also note that to make `#distance` able to assume the fingerprint resolution from the size of Integer that represents it, the change in its structure was needed (left half of bits was swapped with right one), so fingerprints between versions 0.0.4 and 0.0.5 became incompatible, but you probably can convert them manually. Otherwise if we put the version or structure information inside fingerprint it would became slow to (de)serialize and store.

## Development

* OS X El Captain and rbenv may cause environment issues that would make you do things like:

        $ ./ruby `rbenv which rake` compare_matrixes

    instead of just

        $ rake compare_matrixes

    For more information on that: https://github.com/jcupitt/ruby-vips/issues/141

* On macOS, when you do `bundle install` it may fail to install `rmagick` gem (`dhash` gem dependency) saying:

        ERROR: Can't install RMagick 4.0.0. Can't find magick/MagickCore.h.

    To resolve this do:

        $ brew install imagemagick@6
        $ LDFLAGS="-L/usr/local/opt/imagemagick@6/lib" CPPFLAGS="-I/usr/local/opt/imagemagick@6/include" bundle install

* If you get `No package 'MagickCore' found` try:

        $ PKG_CONFIG_PATH="/usr/local/Cellar/imagemagick@6/6.9.10-74/lib/pkgconfig" bundle install

* You might need to prepend `bundle exec` to all the `rake` commands.

* Execute the `rake compare_quality` at least once before executing other rake tasks because it's currently the only one that downloads the test images.

* The tag `v0.0.0.4` is not semver and not real gem version -- it's only for Github Actions testing purposes.

## Credits

[John Cupitt](https://github.com/jcupitt) (libvips and ruby-vips maintainer) helped me a lot.
