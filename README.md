# About

dHash is for measuring the similarity of two images.

Read "Kind of Like That" blog post (21 January 2013): http://www.hackerfactor.com/blog/index.php?/archives/529-Kind-of-Like-That.html

It does not automatically detect very shifted crops and rotated images but you may make a wrapper that would call the comparison function iteratively.

This implementation is powered by Vips and was forked from https://github.com/maccman/dhash that used ImageMagick.

# Installation

    brew install vips

If you have troubles with above, see https://jcupitt.github.io/libvips/install.html  
Then:

    gem install dhash-vips

If you have troubles with the `gem vips` dependency, see https://github.com/jcupitt/ruby-vips  

# Usage

    hash1 = DhashVips.calculate "photo1.jpg"
    hash2 = DhashVips.calculate "photo2.jpg"

    if 10 > DhashVips.hamming(hash1, hash2)
      puts "Images are very similar"
    elsif 20 > DhashVips.hamming(hash1, hash2)
      puts "Images are slightly similar"
    else
      puts "Images are different"
    end

These `10` and `20` numbers are found empirically and just work enough well for 8-byte hashes.
