require_relative "dhash-vips/version"
require "vips"

module DHashVips
  module DHash

    extend self

    def hamming a, b
      (a ^ b).to_s(2).count "1"
    end

    def pixelate file, hash_size, kernel = nil
      image = Vips::Image.new_from_file file
      if kernel
        image.resize((hash_size + 1).fdiv(image.width), vscale: hash_size.fdiv(image.height), kernel: kernel).colourspace("b-w")
      else
        image.resize((hash_size + 1).fdiv(image.width), vscale: hash_size.fdiv(image.height)                ).colourspace("b-w")
      end
    end

    def calculate file, hash_size = 8, kernel = nil
      image = pixelate file, hash_size, kernel

      image.cast("int").conv([1, -1]).crop(1, 0, 8, 8).>(0)./(255).cast("uchar").to_a.join.to_i(2)
    end

  end

end
