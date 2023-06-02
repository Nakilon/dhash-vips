![Gem version](https://badge.fury.io/rb/dhash-vips.svg)
![Benchmark](https://github.com/nakilon/dhash-vips/workflows/Benchmark/badge.svg)

# dHash and IDHash gem powered by ruby-vips

The **dHash** is the algorithm of image fingerprinting that can be used to measure the similarity of two images.  
The **IDHash** is the new algorithm that has some improvements over dHash -- I'll describe it further.

The idea of these algorithms is that you resize the original image to 8x9 and then convert it to 8x8 array of bits -- each tells if the corresponding segment of the image is brighter or darker than the one on the right (or left). Then you apply the [Hamming distance](https://en.wikipedia.org/wiki/Hamming_distance) to such arrays to measure how much they are different.

There were several Ruby implementations on Github already but they all depended on ImageMagick. My implementation takes an advantage of speed of the libvips (the `ruby-vips` gem) -- it fingerprints images much faster. For even more speed the fingerprint comparison function is implemented as native C extension.

## IDHash (the Important Difference Hash)

The main improvement over the dHash is what makes it insensitive to the resizing algorithm and possible errors due to color scheme conversion.

* The "Importance" is an array of extra 64 bits that tells the comparing function which half of 64 bits is important (when the difference between neighbors was enough significant) and which is not. So not every bit in a fingerprint is being compared but only half of them.  
* It subtracts not only horizontally but also vertically -- that adds 128 more bits.  
* Instead of resizing to 8x9 it resizes to 8x8 and puts the image on a torus so it subtracts the very left column from the very right one and the top from the bottom.

So due to implementation and algorithm according to a benchmark the gem has the highest speed and quality compared to other gems (lower numbers are better):

              Fingerprint  Compare  1/FMI^2
    Phamilie        4.575    0.642    3.000
       Dhash        4.785    1.147    1.222
      IDHash        0.221    0.112    1.111
       DHash        0.283    0.903    1.688

### Example

Here are two photos (by Brian Lauer):  
![](http://gems.nakilon.pro.storage.yandexcloud.net/dhash-vips/idhash_example_in.png)  
and visualization of IDHash (`rake compare_images -- image1.jpg image2.jpg`):  
![](http://gems.nakilon.pro.storage.yandexcloud.net/dhash-vips/idhash_example_out.png)  

Here in each of 64 cells, there are two circles that color the difference between that cell and the neighbor one. If the difference is low the Importance bit is set to zero and the circle is invisible. So there are 128 pairs of corresponding circles and when you take one, if at least one circle is visible and is of different color the line is to be drawn. Here you see 15 lines and so the distance between fingerprints will be equal to 15 (that is pretty low and can be interpreted as "images look similar"). Also, you see here that floor on this photo matters -- classic dHash won't see that it's darker than wall because it's comparing only horizontal neighbors and if one photo had no floor the distance function won't notice that. Also, it sees the Important difference between the very right and left columns because the wall has a slow but visible gradient.

### Remaining problems

* Neither dHash nor IDHash can't automatically detect very shifted crops and rotated images but you can make a wrapper that would call the comparison function iteratively.  
* These algorithms are color blind because of converting an image to grayscale. If you take a photo of something in your yard the sun will create lights and shadows, but if you compare photos of something green painted on a blue wall there is a possibility the machine would see nothing painted at all. The `dhash` gem had such image in specs and that made them pretty useless (this was supposed to be a face):  
![](http://gems.nakilon.pro.storage.yandexcloud.net/dhash-vips/colorblind.png)  
* If you have a pile of 1000000 images comparing them with each other would take a month or two. To improve the process in case of dHash that uses Hamming distance you may want to read these threads on Stackexchange network:  
  * [How to find the closest pairs of a string of binary bins in Ruby without O^2 issues?](https://stackoverflow.com/q/8734034/322020)  
  * [Find all pairs of values that are close under Hamming distance](https://cstheory.stackexchange.com/q/18516/27420)  
  * [Finding the closest pair between two sets of points on the hypercube](https://cstheory.stackexchange.com/q/16322/27420)  
  * [Would PCA work for boolean data types?](https://stats.stackexchange.com/q/159705/1125)  
  * [Using pHash to search agaist a huge image database, what is the best approach?](https://stackoverflow.com/q/18257641/322020)  
  * [How do I speed up this BIT_COUNT query for hamming distance?](https://stackoverflow.com/q/35065675/322020)  
  * [Hamming distance on binary strings in SQL](https://stackoverflow.com/q/4777070/322020)

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
if distance < 20
  puts "Images are very similar"
elsif distance < 25
  puts "Images are slightly similar"
else
  puts "Images are different"
end
```

## Notes and benchmarks

* The above `20` and `25` constants are found empirically and just work enough well for 8-byte hashes. To find these thresholds you can run a rake task with hardcoded test cases (pairs of photos from the same photosession are not the same but are considered to be enough 'similar' for the purpose of this benchmark):

      $ rake compare_quality

                            Dhash  Phamilie  DHashVips::DHash  DHashVips::IDHash  DHashVips::IDHash(4)
          The same image:    0..0      0..0              0..0               0..0                  0..0
      'Jordan Voth case':       2         2                 7                  0                     0
          Similar images:   1..15    14..34             2..23              8..22               56..166
        Different images:  10..56    22..42             9..50             22..70              116..230
                1/FMI^2 =   1.222       3.0             1.688              1.111                 1.266
                 FP, FN =  [2, 0]    [0, 6]            [4, 1]             [1, 0]                [1, 1]

    The `FMI` line (smaller number is better) here is the "quality of algorithm", i.e. the best achievable function for the ["Fowlkes–Mallows index"](https://en.wikipedia.org/wiki/Fowlkes%E2%80%93Mallows_index) value if you take the "similar" and "different" test pairs and try to draw the threshold line. For IDHash it's empirical value of 22 as you acn see above that means it's the only algorithm that allowed to separate "similar" from "different" comparisons for our test cases.  
    The last line shows number of false positives (`FP`) and false negatives (`FN`) in case of the best achieved FMI.  
    The [`phamilie` gem](https://github.com/toy/phamilie) is a DCT based fingerprinting tool (not a kind of dhash).

* Methods were renamed from `#calculate` to `#fingerprint` and from `#hamming` to `#distance`.  
* The `DHash#calculate` accepts `hash_size` optional parameter that is 8 by default. The `IDHash#fingerprint`'s optional parameter is called `power` and works in a bit different way: 3 means 8 and 4 means 16 -- other sizes are not supported because they don't seem to be useful (higher fingerprint resolution makes it vulnerable to image shifts and croppings, also `#distance` becomes much slower). Because IDHash's fingerprint is more complex than DHash's one it's not that straight forward to compare them so under the hood the `#distance` method have to check the size of fingerprint. If you are sure that fingerprints were made with power=3 then to skip the check you may use the `#distance3` method directly.  
* The `#distance3` method will try to compile and use the Ruby C extension that is around 15 times faster than pure Ruby implementation. Native extension currently works on macOS rbenv Ruby from 2.3.8 to at least 2.7.0-preview2 installed with rbenv `-k` flag. So the full benchmark:

  * Ruby 2.3.8p459:

        load the image and calculate the fingerprint:
                                  user     system      total        real
        Dhash                 6.191731   0.230885   6.422616 (  6.428763)
        Phamilie              5.361751   0.037524   5.399275 (  5.402553)
        DHashVips::DHash      0.858045   0.144820   1.002865 (  0.924308)
        DHashVips::IDHash     0.769975   0.071087   0.841062 (  0.790470)
        DHashVips::IDHash 4   0.805311   0.077918   0.883229 (  0.825897)

        measure the distance (32*32*2000 times):
                                               user     system      total        real
        Dhash hamming                      1.810000   0.000000   1.810000 (  1.824719)
        Phamilie distance                  1.000000   0.010000   1.010000 (  1.006127)
        DHashVips::DHash hamming           1.810000   0.000000   1.810000 (  1.817415)
        DHashVips::IDHash distance         1.400000   0.000000   1.400000 (  1.401333)
        DHashVips::IDHash distance3_ruby   3.320000   0.010000   3.330000 (  3.337920)
        DHashVips::IDHash distance3_c      0.210000   0.000000   0.210000 (  0.212864)
        DHashVips::IDHash distance 4       8.300000   0.120000   8.420000 (  8.499735)

* There is a benchmark that runs both speed and quality tests summing results as a single table (observe that results may depend on the libvips version):

      ruby 2.3.8p459 (2018-10-18 revision 65136) [x86_64-darwin18]
      vips-8.11.3-Wed Aug 11 09:29:27 UTC 2021
      Version: ImageMagick 6.9.12-23 Q16 x86_64 2021-09-18 https://imagemagick.org
      Intel(R) Core(TM) i5-7360U CPU @ 2.30GHz
      gem ruby-vips version 2.1.4
      gem rmagick version 4.2.5

                Fingerprint  Compare  1/FMI^2
      Phamilie        4.575    0.642    3.000
         Dhash        4.785    1.147    1.222
        IDHash        0.221    0.112    1.111
         DHash        0.283    0.903    1.688

      ruby 2.7.2p137 (2020-10-01 revision 5445e04352) [x86_64-linux]
      Version: 8.7.4-1+deb10u1
      Version: 8:6.9.10.23+dfsg-2.1+deb10u1

                Fingerprint  Compare  1/FMI^2
      Phamilie       19.630    1.302    3.000
         Dhash        6.713    1.373    1.222
        IDHash        2.177    0.210    1.111
         DHash        1.063    1.318    1.444

      ruby 3.1.3p185 (2022-11-24 revision 1a6b16756e) [x86_64-linux]
      Version: 8.10.5-2
      Version: 8:6.9.11.60+dfsg-1.3

                Fingerprint  Compare  1/FMI^2
      Phamilie       50.953    0.793    3.000
         Dhash        7.228    1.129    1.222
        IDHash        0.655    0.131    1.111
         DHash        1.850    1.035    1.688

* Also note that to make `#distance` able to assume the fingerprint resolution from the size of Integer that represents it, the change in its structure was needed (left half of bits was swapped with right one), so fingerprints between versions 0.0.4.1 and 0.0.5.0 became incompatible, but you probably can convert them manually. Otherwise if we put the version or structure information inside fingerprint it would became slow to (de)serialize and store.  
* The version `0.2.0.0` has grayscaling bug fixed and some tweak. It made DHash a bit worse and IDHash a bit better. Fingerprints recalculation is recommended.
* The version `0.2.3.0` has an important alpha layer transparency bug fix. Fingerprints recalculation is recommended.

## Possible issues

* OS X El Captain and rbenv may cause environment issues that would make you do things like:

        $ ./ruby `rbenv which rake` compare_matrixes

    instead of just

        $ rake compare_matrixes

    For more information on that: https://github.com/jcupitt/ruby-vips/issues/141

## Development notes

* To run unit tests in current env

      $ ruby extconf.rb && make clean && make   # otherwise you might get silenced LoadError due to switching between rubies
      $ bundle exec ruby test.rb && bundle exec ruby test_LoadError.rb

* To run unit tests under all available latest major rbenv ruby versions

      $ ruby test_rbenv.rb

* Current (this is outdated) Ruby [packages](https://pkgs.alpinelinux.org/packages) for `apk add` (Alpine Linux) and existing official Ruby docker [images](https://hub.docker.com/_/ruby?tab=tags) per Alpine version:

        packages     ruby docker hub
        3.12 2.7.1                2.5.8 2.6.6 2.7.1
        3.11 2.6.6         2.4.10 2.5.8 2.6.6 2.7.1
        3.10 2.5.8         2.4.10 2.5.8 2.6.6 2.7.1
        3.9  2.5.8         2.4.9  2.5.7 2.6.5 2.7.0p1
        3.8  2.5.8   2.3.8 2.4.6  2.5.5 2.6.3
        3.7  2.4.6   2.3.8 2.4.5  2.5.3 2.6.0
        3.6  2.4.6         2.4.5  2.5rc
        3.5  2.3.8
        3.4  2.3.7   2.3.7 2.4.4
        3.3  2.2.9

    The gem has been tested on macOS rbenv versions: 2.3.8, 2.4.9, 2.5.7, 2.6.5, 2.7.0-preview2

* To quickly find out what does the dhash-vips Docker image include (TODO: write in this README about the existing Docker images):

        docker run --rm <image_name> sh -c "cat /etc/alpine-release; ruby -v; vips -v"

* You may get this:

        Can't install RMagick 2.16.0. Can't find MagickWand.h.

    because Imagemagick sucks but we need it to benchmark alternative gems, so:

        $ brew install imagemagick@6
        $ brew unlink imagemagick@7
        $ brew link imagemagick@6 --force

* On macOS, when you do `bundle install` it may fail to install `rmagick` gem (`dhash` gem dependency) saying:

        ERROR: Can't install RMagick 4.0.0. Can't find magick/MagickCore.h.

    To resolve this do:

        $ brew install imagemagick@6
        $ LDFLAGS="-L/usr/local/opt/imagemagick@6/lib" CPPFLAGS="-I/usr/local/opt/imagemagick@6/include" bundle install

* If you get `No package 'MagickCore' found` try:

        $ PKG_CONFIG_PATH="/usr/local/Cellar/imagemagick@6/6.9.10-74/lib/pkgconfig" bundle install

* You might get:

        NameError: uninitialized constant Magick::Rec601LumaColorspace
        Did you mean?  Magick::Rec601YCbCrColorspace

    try

        $ brew unlink imagemagick
        $ brew link imagemagick@6
        $ gem uninstall rmagick   # select 2.x
        $ bundle install

* Execute the `rake compare_quality` at least once before executing other rake tasks because it's currently the only one that downloads the test images.

* The tag `v0.0.0.4` is not semver and not real gem version -- it's only for Github Actions testing purposes.

* Phamilie works with filenames instead of fingerprints and caches them but not distances.

## Credits

libvips maintainers [John Cupitt](https://github.com/jcupitt) and [Kleis Auke Wolthuizen](https://github.com/kleisauke) helped with this a lot.
