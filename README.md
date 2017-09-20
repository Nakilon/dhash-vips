# Dhash

Dhash's (or difference hashes) are a way of calculating similarity between images. If two images have a similar dhash, then the likelihood is that they both are depicting the same image (albeit slightly cropped compressed etc).

For more information, check out the links below.

- http://hackerlabs.org/blog/2012/07/30/organizing-photos-with-duplicate-and-similarity-checking/
- http://www.hackerfactor.com/blog/?/archives/529-Kind-of-Like-That.html
- http://www.hackerfactor.com/blog/index.php?/archives/432-Looks-Like-It.html
- http://blog.iconfinder.com/detecting-duplicate-images-using-python/

## Installation

    gem 'dhash'

## Usage

    hash1 = Dhash.calculate('face-high.jpg')
    hash2 = Dhash.calculate('face-low.jpg')

    if Dhash.hamming(hash1, hash2) < 10
      puts "Images are very similar"
    else
      puts "No match"
    end
