[![Gem Version](https://badge.fury.io/rb/dhash-vips.svg)](http://badge.fury.io/rb/dhash-vips)

# dHash and IDHash gem powered by ruby-vips

The "dHash" is an algorithm of fingerprinting that can be used to measure the similarity of two images.

You may read about it in "Kind of Like That" blog post (21 January 2013): http://www.hackerfactor.com/blog/index.php?/archives/529-Kind-of-Like-That.html  
The original idea is that you split the image into 64 segments and so there are 64 bits -- each tells if the one segment is brighter or darker than the neighbor one. Then the [Hamming distance](https://en.wikipedia.org/wiki/Hamming_distance) between fingerprints is the opposite of images similarity.

There are several implementations on Github already but they all depend on ImageMagick. My implementation takes an advantage of libvips (the `ruby-vips` gem) -- it also uses the `.conv` method and in result converts image to an array of grayscale bytes almost 10 times faster:
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

Here the `Dhash` is a https://github.com/maccman/dhash that I used earlier in my projects.  
The `DHashVips::DHash` is a port of it that uses vips. I would like to tell you that you can replace the `dhash` with `dhash-vips` gem right now but it appeared to have a barely noticeable issue. There is a lot of magic behind the libvips speed and resizing -- you may not notice it with unarmed eyes but when two neighbor segments are enough similar by luminosity the difference can change the sign. So I found two identical images that were just of different colorspace and size (photo by Jordan Voth):  
![](https://storage.googleapis.com/dhash-vips.nakilon.pro/dhash_issue_example.png)  
but the distance between their hashes appeared to be equal to 5 while `dhash` gem reported 0.

This is why `DHashVips::IDHash` appeared.

## IDHash (the Important Difference Hash)

It has improvements over the dHash that made hashing less sensitive to the resizing algorithm and effectively made the pair of images mentioned above to have a distance of 0 again. Three improvements are:  
* The "Importance" is an array of extra 64 bits that tells the comparing function which half of 64 bits is important (when the difference between neighbors was enough significant) and which is not. So not every bit in a hash is being compared but only half of them.
* It subtracts not only horizontally but also vertically -- that adds 128 more bits.
* Instead of resizing to 9x8 it resizes to 8x8 and puts the image on a torus so it subtracts the left column from the right one and the top from bottom.

For example, here are two photos (by Brian Lauer):  
![](https://storage.googleapis.com/dhash-vips.nakilon.pro/idhash_example_in.png)  
and visualization of IDHash (`rake compare_images -- image1.jpg image2.jpg`):  
![](https://storage.googleapis.com/dhash-vips.nakilon.pro/idhash_example_out.png)  

Here in each of 64 cells, there are two circles that color the difference between that cell and the neighbor one. If the difference is low the Importance bit is set to zero and the circle is invisible. So there are 128 pairs of corresponding circles and when you take one, if at least one circle is visible and is of different color the line is to be drawn. Here you see 15 lines and so the distance between hashes will be equal to 15 (that is pretty low and can be interpreted as "images look similar"). Also, you see here that floor on this photo matters -- classic dHash won't see that it's darker than wall because it's comparing only horizontal neighbors and if one photo had no floor the distance function won't notice that. Also, it sees the Important difference between the very right and left columns because the wall has a slow but visible gradient.

You could see in hash calculation benchmark earlier that these improvements didn't make it slower than dHash because most of the time is spent on image resizing. The calculation of distance is what became two times slower:
```ruby
((a | b) & (a >> 128 ^ b >> 128)).to_s(2).count "1"
```
vs
```ruby
(a ^ b).to_s(2).count "1"
```

Remaining problems:  
* Neither dHash nor IDHash can't automatically detect very shifted crops and rotated images but you can make a wrapper that would call the comparison function iteratively.  
* These algorithms are color blind because of converting an image to grayscale. If you take a photo of something in your yard the sun will create lights and shadows, but if you compare photos of something green painted on a blue wall there is a possibility the machine would see nothing painted at all. The `dhash` gem had such image in specs and that made them pretty useless (this was supposed to be a face):  
![](https://storage.googleapis.com/dhash-vips.nakilon.pro/colorblind.png)  
* If you have a pile of 1000000 images to compare them with each other that would take a month or two. To improve the process you in case of DHashVips::DHash that uses Hamming distance you may want to read these:  
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

These `10` and `20` numbers are found empirically and just work enough well for 8-byte hashes.

### IDHash:

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

## Credits

[John Cupitt](https://github.com/jcupitt) (libvips and ruby-vips maintainer) helped me a lot.
