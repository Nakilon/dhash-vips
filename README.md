[![Gem Version](https://badge.fury.io/rb/dhash-vips.svg)](http://badge.fury.io/rb/dhash-vips)

# dHash and IDHash gem powered by ruby-vips

The "dHash" is an algorithm of fingerprinting that can be used to measure the similarity of two images.

You may read about it in "Kind of Like That" blog post (21 January 2013): http://www.hackerfactor.com/blog/index.php?/archives/529-Kind-of-Like-That.html  
The original idea is that you split the image into 64 segments and so there are 64 bits -- each tells if the one segment is brighter or darker than the neighbor one. Then the [Hamming distance](https://en.wikipedia.org/wiki/Hamming_distance) between fingerprints is the opposite of images similarity.

There were several implementations on Github already but they all depend on ImageMagick. My implementation takes an advantage of libvips (the `ruby-vips` gem) -- it also uses the `.conv` method and in result converts image to an array of grayscale bytes almost 10 times faster:

    load and calculate the fingerprint:
                              user     system      total        real
    Dhash                13.110000   0.950000  14.060000 ( 14.537057)
    DHashVips::DHash      1.480000   0.310000   1.790000 (  1.808787)
    DHashVips::IDHash     1.080000   0.100000   1.180000 (  1.156446)

    measure the distance (1000 times):
                              user     system      total        real
    Dhash hamming         1.770000   0.010000   1.780000 (  1.815612)
    DHashVips::DHash      1.810000   0.010000   1.820000 (  1.875666)
    DHashVips::IDHash     3.430000   0.020000   3.450000 (  3.499031)

Here the `Dhash` is [another gem](https://github.com/maccman/dhash) that I used earlier in my projects.  
The `DHashVips::DHash` is a port of it that uses vips. I would like to tell you that you can replace the `dhash` with `dhash-vips` gem right now but it appeared to have a barely noticeable issue. There is a lot of magic behind the libvips speed and resizing -- you may not notice it with unarmed eyes but when two neighbor segments are enough similar by luminosity the difference can change the sign. So I found two identical images that were just of different colorspace and size (photo by Jordan Voth):  
![](https://storage.googleapis.com/dhash-vips.nakilon.pro/dhash_issue_example.png)  
but the distance between their hashes appeared to be equal to 5 while `dhash` gem reported 0.

This is why `DHashVips::IDHash` appeared.

## IDHash (the Important Difference Hash)

It has improvements over the dHash that made fingerprinting less sensitive to the resizing algorithm and effectively made the pair of images mentioned above to have a distance of 0 again. Three improvements are:  
* The "Importance" is an array of extra 64 bits that tells the comparing function which half of 64 bits is important (when the difference between neighbors was enough significant) and which is not. So not every bit in a fingerprint is being compared but only half of them.  
* It subtracts not only horizontally but also vertically -- that adds 128 more bits.  
* Instead of resizing to 9x8 it resizes to 8x8 and puts the image on a torus so it subtracts the left column from the right one and the top from bottom.

You could see in fingerprint calculation benchmark earlier that these improvements didn't make it slower than dHash because most of the time is spent on image resizing (at some point it actually even became faster, idk why). The calculation of distance is what became two times slower:
```ruby
((a | b) & ((a ^ b) >> 128)).to_s(2).count "1"
```
vs
```ruby
(a ^ b).to_s(2).count "1"
```

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

If you have troubles with the `gem ruby-vips` dependency, see https://github.com/jcupitt/ruby-vips  

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

These `15` and `25` numbers are found empirically and just work enough well for 8-byte hashes.  
To find out these tresholds we can run a rake task with hardcoded test cases:

    $ rake compare_quality

    Dhash 
    Absolutely the same image: 0..0
    Complex B/W and the same but colorful: 4
    Similar images: 7..17
    Different images: 9..44

    Phamilie 
    Absolutely the same image: 0..0
    Complex B/W and the same but colorful: 2
    Similar images: 14..28
    Different images: 22..40

    DHashVips::DHash 
    Absolutely the same image: 0..0
    Complex B/W and the same but colorful: 4
    Similar images: 10..16
    Different images: 9..42

    DHashVips::IDHash 
    Absolutely the same image: 0..0
    Complex B/W and the same but colorful: 0
    Similar images: 6..22
    Different images: 18..64

    DHashVips::IDHash 4
    Absolutely the same image: 0..0
    Complex B/W and the same but colorful: 0
    Similar images: 78..120
    Different images: 120..213

### Notes

* Methods were renamed from `#calculate` to `#fingerprint` and from `#hamming` to `#distance`.  
* The `DHash#calculate` accepts `hash_size` optional parameter that is 8 by default. The `IDHash#fingerprint`'s optional parameter is called `power` and works in a bit different way: 3 means 8 and 4 means 16 -- other sizes are not supported because they don't seem to be useful (higher fingerprint resolution makes it vulnerable to image shifts and croppings, also `#distance` becomes much slower). Because IDHash's fingerprint is more complex than DHash's one it's not that straight forward to compare them so under the hood the `#distance` methods have to check the size of fingerprint -- this trade-off costs 30-40% of speed that can be eliminated by using `#distance3` method that assumes fingerprint to be of power=3. So the full benchmark is this one:

  * Ruby 2.0.0

        $ bundle exec rake compare_speed

        load and calculate the fingerprint:
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

        load and calculate the fingerprint:
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

  * Ruby 2.6.3p62 (2.3.8, 2.4.6 and 2.5.5 are all similar) with newer CPU (`sysctl -n machdep.cpu.brand_string #=> Intel(R) Core(TM) i5-7360U CPU @ 2.30GHz`):

        load and calculate the fingerprint:
                                  user     system      total        real
        Dhash                 6.191731   0.230885   6.422616 (  6.428763)
        Phamilie              5.361751   0.037524   5.399275 (  5.402553)
        DHashVips::DHash      0.858045   0.144820   1.002865 (  0.924308)
        DHashVips::IDHash     0.769975   0.071087   0.841062 (  0.790470)
        DHashVips::IDHash 4   0.805311   0.077918   0.883229 (  0.825897)

        measure the distance (1000 times):
                                            user     system      total        real
        Dhash hamming                   0.845866   0.000544   0.846410 (  0.847105)
        Phamilie distance               0.464094   0.000292   0.464386 (  0.464639)
        DHashVips::DHash hamming        0.843819   0.000585   0.844404 (  0.844961)
        DHashVips::IDHash distance      2.007639   0.001255   2.008894 (  2.009921)
        DHashVips::IDHash distance3     1.643094   0.001005   1.644099 (  1.645249)
        DHashVips::IDHash distance 4    3.458882   0.011378   3.470260 (  3.472131)

      Here I've added the [`phamilie` gem](https://github.com/toy/phamilie) that is DCT based (not a kind of dhash). It is slow in fingerprinting but fast in distance measurement (because it's a Ruby C extension). Previously in this document you could notice the `compare_quality` benchmark that showed it's also comparable to the IDHash quality.

* Also note that to make `#distance` able to assume the fingerprint resolution from the size of Integer that represents it, the change in its structure was needed (left half of bits was swapped with right one), so fingerprints between versions 0.0.4 and 0.0.5 became incompatible, but you probably can convert them manually. I know, incompatibilities suck but if we put the version or structure information inside fingerprint it will became slow to (de)serialize and store.

## Troubleshooting

OS X El Captain and rbenv may cause environment issues that would make you do things like:

    $ ./ruby `rbenv which rake` compare_matrixes

instead of just

    $ rake compare_matrixes

For more information on that: https://github.com/jcupitt/ruby-vips/issues/141

## Development

* On macOS, when you do `bundle install` it may fail to install `rmagick` gem (`dhash` gem dependency) saying:

        ERROR: Can't install RMagick 4.0.0. Can't find magick/MagickCore.h.

    To resolve this do:

        $ brew install imagemagick@6
        $ LDFLAGS="-L/usr/local/opt/imagemagick@6/lib" CPPFLAGS="-I/usr/local/opt/imagemagick@6/include" bundle install

* If you get `No package 'MagickCore' found` try:

        $ PKG_CONFIG_PATH="/usr/local/Cellar/imagemagick@6/6.9.10-74/lib/pkgconfig" bundle install

* You might need to prepend `bundle exec` to all the `rake` commands.

* Execute the `rake compare_quality` at least once before executing other rake tasks because it's currently the only one that downloads the test images.

## Credits

[John Cupitt](https://github.com/jcupitt) (libvips and ruby-vips maintainer) helped me a lot.
