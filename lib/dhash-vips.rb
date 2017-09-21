require_relative "dhash-vips/version"
require "vips"

module DhashVips
  extend self

  def hamming a, b
    (a ^ b).to_s(2).count "1"
  end

  def calculate file, hash_size = 8
    image = Vips::Image.new_from_file file
    image = image.resize((hash_size + 1).fdiv(image.width), vscale: hash_size.fdiv(image.height)).colourspace "b-w"

    difference = 0

    hash_size.times do |row|
      hash_size.times do |col|
        pixel_left  = image.getpoint(col    , row).first
        pixel_right = image.getpoint(col + 1, row).first
        difference <<= 1
        difference += 1 if pixel_left > pixel_right
      end
    end

    difference
  end

end
