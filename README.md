[![Gem Version](https://badge.fury.io/rb/dhash-vips.svg)](http://badge.fury.io/rb/dhash-vips)  

# dHash and IDHash gem powered by ruby-vips

The "dHash" is an algorithm of hashing that can be used for measuring the similarity of two images.

You may read about it in "Kind of Like That" blog post (21 January 2013): http://www.hackerfactor.com/blog/index.php?/archives/529-Kind-of-Like-That.html  
The original idea is that you split the image into 64 segments and so there are 64 bits -- each tells if the one segment is brighter or darker than the neighbor one.

There are several implementations on Github already but they all depend on ImageMagick. My implementation takes an advantage of libvips (the `ruby-vips` gem) -- it also uses the `.conv` method and in result converts image to an array almost 10 times faster:
```
$ rake compare_speed

load and calculate:
                         user     system      total        real
Dhash               12.610000   0.850000  13.460000 ( 13.726590)
DHashVips::DHash     1.280000   0.250000   1.530000 (  1.435285)
DHashVips::IDHash    1.240000   0.160000   1.400000 (  1.315536)

distance (1000 times):
                         user     system      total        real
Dhash                2.500000   0.050000   2.550000 (  2.579340)
DHashVips::DHash     2.350000   0.020000   2.370000 (  2.401252)
DHashVips::IDHash    5.190000   0.040000   5.230000 (  5.279742)
```
(`rake compare_speed`)

The `Dhash` above is a https://github.com/maccman/dhash that I used earlier in my projects.  
The `DHashVips::DHash` is a port of it that uses vips. I would like to tell you that you can replace the `dhash` with `dhash-vips` gem right now but it appeared to have barely noticable issues. There is a lot of magic behind the libvips speed and about resizing -- you may not notice it with your eyes but when two neighbour segments are enough similar by luminosity the difference can change the sign. So I found two similar images that were just of different colorspace and size but the difference between their hashes was equal to 5 while the `dhash` gem tells 0.

# IDHash

This is how `DHashVips::IDHash` appeared. I called it "IDHash" (the Imprortant Difference Hash) and it has three improvements that effectively made the pair of images mentioned above to have distance of 0 again. Three improvements of it over the dHash are:  
* The "Importance" is an array of extra 64 bits that tells the comparing function which half of 64 bits are important (when the difference between neighbors was enough significant) and which is not. So it's like not every bit in a hash is being compared but only half of them.
* It substracts not only horizontally but also vertically -- that adds 128 more bits.
* Instead of resizing to 9x8 it resizes to 8x8 and puts the image on a torus so it substracts the left column from right and the top from bottom.

For example, here are two photos (by Brian Lauer):  
![](https://storage.googleapis.com/dhash-vips.nakilon.pro/idhash_example_in.png)  
And visualisation of IDHash:  
![](https://storage.googleapis.com/dhash-vips.nakilon.pro/idhash_example_out.png)  
(`rake compare_images -- image1.jpg image2.jpg`)

Here in each of 64 cells there are two circles that color the difference between that cell and the neighbor one. If the difference is low the Importance bit is set to zero and the circle is invisible. When you take a pair of corresponding circles, if at least one is visible and is of different color the line is to be drawn. Here you see 15 lines and so the distance between hashes will be equal to 15 (that is pretty low and can be interpreted as a similarity). Also you see here that floor on this photo matters -- classic dHash won't see that it's darker than wall because it's comparing only horizontal neighbors. Also it sees the Important difference between the very right and left columns because the wall has a slow but visible gradient.

You can see in hash calculation benchmark that these improvements didn't make it slower than dHash because most of time is spent on image resizing. The calculation of distance is what became two times slower:
```ruby
((a | b) & (a >> 128 ^ b >> 128)).to_s(2).count "1"
```
vs
```ruby
(a ^ b).to_s(2).count "1"
```

Remaining problems:  
* Neither dHash nor IDHash can't automatically detect very shifted crops and rotated images but you can make a wrapper that would call the comparison function iteratively.  
* These algorithms are color blind because of converting image to grayscale. If you take a photo of something in your yard the sun with create lights and shadows, but if you compare photos of something green painted on a blue wall there is a possibility the machine would see nothing at all painted. The `dhash` gem had such test image and that made its specs useless: https://storage.googleapis.com/dhash-vips.nakilon.pro/colorblind.png  
* If you have a pile of 1000000 images to compare them with each other would need a month or two. In case of dHash that uses [Hamming distance](https://en.wikipedia.org/wiki/Hamming_distance) to compare 

# Installation

    brew install vips

If you have troubles with above, see https://jcupitt.github.io/libvips/install.html  
Then:

    gem install dhash-vips

If you have troubles with the `gem ruby-vips` dependency, see https://github.com/jcupitt/ruby-vips  
Here I had some issues on CentOS https://github.com/jcupitt/ruby-vips/issues/104 but the last time it was smooth.

# Usage

## dHash:

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

These `10` and `20` numbers are found empirically and just work enough well for 8-byte hashes.

## IDHash:

```ruby
require "dhash-vips"

hash1 = DHashVips::IDHash.calculate "photo1.jpg"
hash2 = DHashVips::IDHash.calculate "photo2.jpg"

distance = DHashVips::IDHash.distance hash1, hash2
if distance < 10
  puts "Images are very similar"
elsif distance < 25
  puts "Images are slightly similar"
else
  puts "Images are different"
end
```

Note that `DHash#calculate` accepts `hash_size` optional parameter that sets hash size in bytes, but `IDHash` size is currently hardcoded and can't be adjusted.

# Credits

[John Cupitt](https://github.com/jcupitt) (the libvips and ruby-vips maintainer) helped me a lot.
