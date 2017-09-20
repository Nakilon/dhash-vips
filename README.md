# About

dHash is for measuring the similarity of two images.

Read "Kind of Like That" Monday, 21 January 2013: http://www.hackerfactor.com/blog/index.php?/archives/529-Kind-of-Like-That.html

It does not automatically detect very shifted crops and rotated images but you may make a wrapper that would call the comparison function iteratively.

Forked from https://github.com/maccman/dhash by Alex MacCaw

# Installation

    gem install dhash-vips

# Usage

    hash1 = DhashVips.calculate "face-high.jpg"
    hash2 = DhashVips.calculate "face-low.jpg"

    if 10 > DhashVips.hamming(hash1, hash2)
      puts "Images are very similar"
    else
      puts "No match"
    end
