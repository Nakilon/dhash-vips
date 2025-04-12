require "minitest/autorun"

require_relative "lib/dhash-vips"

# TODO tests about `fingerprint(4)`

[
  [DHashVips::DHash, :hamming, :calculate, 2, 23, 16, 50, 7, 0x7919395919191919],

    # v0.2.3.0
    # [[0, 18, 26, 28, 28, 24, 35, 31, 42, 42, 32, 34, 33, 29, 35, 40],
    #  [18, 0, 30, 24, 38, 34, 33, 33, 44, 42, 38, 42, 41, 37, 37, 50],
    #  [26, 30, 0, 16, 34, 38, 29, 35, 42, 40, 36, 38, 31, 31, 31, 36],
    #  [28, 24, 16, 0, 36, 36, 31, 35, 40, 38, 34, 34, 41, 37, 27, 34],
    #  [28, 38, 34, 36, 0, 14, 35, 33, 40, 42, 32, 26, 27, 33, 35, 28],
    #  [24, 34, 38, 36, 14, 0, 43, 39, 38, 40, 24, 28, 25, 31, 29, 28],
    #  [35, 33, 29, 31, 35, 43, 0, 8, 27, 25, 35, 33, 32, 32, 28, 31],
    #  [31, 33, 35, 35, 33, 39, 8, 0, 27, 27, 35, 33, 34, 34, 28, 33],
    #  [42, 44, 42, 40, 40, 38, 27, 27, 0, 2, 34, 32, 31, 33, 31, 28],
    #  [42, 42, 40, 38, 42, 40, 25, 27, 2, 0, 34, 34, 33, 35, 31, 28],
    #  [32, 38, 36, 34, 32, 24, 35, 35, 34, 34, 0, 10, 23, 31, 25, 18],
    #  [34, 42, 38, 34, 26, 28, 33, 33, 32, 34, 10, 0, 23, 29, 25, 16],
    #  [33, 41, 31, 41, 27, 25, 32, 34, 31, 33, 23, 23, 0, 20, 24, 19],
    #  [29, 37, 31, 37, 33, 31, 32, 34, 33, 35, 31, 29, 20, 0, 22, 27],
    #  [35, 37, 31, 27, 35, 29, 28, 28, 31, 31, 25, 25, 24, 22, 0, 23],
    #  [40, 50, 36, 34, 28, 28, 31, 33, 28, 28, 18, 16, 19, 27, 23, 0]]

  [DHashVips::IDHash, :distance, :fingerprint, 8, 22, 25, 70, 0, 0x1d5cdc0d1d0c1d9f5720a6fff2fe02013f00df9f005e1dc0ff670000ffff0080],

    # v0.2.3.0
    # [[0, 19, 34, 38, 57, 47, 50, 49, 45, 42, 55, 45, 60, 49, 51, 53],
    #  [19, 0, 34, 33, 55, 47, 52, 49, 46, 49, 59, 46, 62, 54, 50, 57],
    #  [34, 34, 0, 8, 48, 55, 46, 42, 55, 57, 45, 35, 51, 45, 46, 47],
    #  [38, 33, 8, 0, 52, 61, 43, 38, 49, 50, 50, 37, 50, 39, 43, 51],
    #  [57, 55, 48, 52, 0, 22, 46, 42, 70, 63, 51, 50, 35, 41, 46, 46],
    #  [47, 47, 55, 61, 22, 0, 54, 54, 57, 53, 39, 44, 43, 41, 45, 38],
    #  [50, 52, 46, 43, 46, 54, 0, 8, 35, 38, 51, 45, 50, 42, 43, 43],
    #  [49, 49, 42, 38, 42, 54, 8, 0, 34, 36, 54, 49, 49, 42, 43, 44],
    #  [45, 46, 55, 49, 70, 57, 35, 34, 0, 10, 53, 55, 56, 50, 49, 49],
    #  [42, 49, 57, 50, 63, 53, 38, 36, 10, 0, 50, 52, 55, 48, 46, 45],
    #  [55, 59, 45, 50, 51, 39, 51, 54, 53, 50, 0, 10, 32, 35, 40, 25],
    #  [45, 46, 35, 37, 50, 44, 45, 49, 55, 52, 10, 0, 30, 27, 37, 26],
    #  [60, 62, 51, 50, 35, 43, 50, 49, 56, 55, 32, 30, 0, 22, 26, 28],
    #  [49, 54, 45, 39, 41, 41, 42, 42, 50, 48, 35, 27, 22, 0, 37, 35],
    #  [51, 50, 46, 43, 46, 45, 43, 43, 49, 46, 40, 37, 26, 37, 0, 22],
    #  [53, 57, 47, 51, 46, 38, 43, 44, 49, 45, 25, 26, 28, 35, 22, 0]]

].each do |lib, dm, calc, min_similar, max_similar, min_not_similar, max_not_similar, bw_exceptional, hash|

  describe lib do
    require "fileutils"
    require "digest"
    require "mll"

    require_relative "common"

    # these are false positive by idhash
    # 1b1d4bde376084011d027bba1c047a4b.jpg
    # 6d97739b4a08f965dc9239dd24382e96.jpg
    [
      [:similar, %w{
        1d468d064d2e26b5b5de9a0241ef2d4b.jpg 92d90b8977f813af803c78107e7f698e.jpg
        309666c7b45ecbf8f13e85a0bd6b0a4c.jpg 3f9f3db06db20d1d9f8188cd753f6ef4.jpg
        679634ff89a31279a39f03e278bc9a01.jpg df0a3b93e9412536ee8a11255f974141.jpg
        54192a3f65bd03163b04849e1577a40b.jpg 6d32f57459e5b79b5deca2a361eb8c6e.jpg
        4b62e0eef58bfbc8d0d2fbf2b9d05483.jpg b8eb0ca91855b657f12fb3d627d45c53.jpg
        21cd9a6986d98976b6b4655e1de7baf4.jpg 9b158c0d4953d47171a22ed84917f812.jpg
        9c2c240ec02356472fb532f404d28dde.jpg fc762fa286489d8afc80adc8cdcb125e.jpg
        7a833d873f8d49f12882e86af1cc6b79.jpg ac033cf01a3941dd1baa876082938bc9.jpg
      }, min_similar, max_similar, min_not_similar, max_not_similar], # slightly similar images
      [:bw_exceptional, %w{
        71662d4d4029a3b41d47d5baf681ab9a.jpg ad8a37f872956666c3077a3e9e737984.jpg
      }, bw_exceptional, bw_exceptional], # these are the same photo but of different size and colorspace
    ].each do |test_name, _images, min, max, min_not, max_not|

      images = _images.map{ |_| download_if_needed "test_images/#{_}" }

      hashes = images.map &lib.method(calc)
      table = MLL::table[lib.method(dm), [hashes], [hashes]]

      # STDERR.puts ""
      # require "pp"
      # PP.pp table, STDERR
      # STDERR.puts ""

      it test_name do
        similar = []
        not_similar = []
        hashes.size.times.to_a.repeated_combination(2) do |i, j|
          case
          when i == j
            assert_predicate table[i][j], :zero?
          when (j - i).abs == 1 && (i + j - 1) % 4 == 0
            # STDERR.puts [table[i][j], min, max].inspect
            similar.push table[i][j]
          else
            # STDERR.puts [table[i][j], min_not_similar, max_not_similar].inspect
            not_similar.push table[i][j]
          end
        end
        assert_equal [min, max], similar.minmax
        assert_equal [min_not, max_not], not_similar.minmax if min_not
      end

    end

    it "accepts Vips::Image" do
      # https://github.com/libvips/ruby-vips/issues/349
      lib.public_send calc, Vips::Image.new_from_buffer("GIF89a\x01\x00\x01\x00\x80\x01\x00\xFF\xFF\xFF\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;", "")
    end

    it "correct calculation" do
      download_if_needed "alpha_only.png"
      t = lib.public_send calc, "alpha_only.png"
      assert_equal hash, t, ->{ "0x#{hash.to_s 16} != 0x#{t.to_s 16}" }
    end

  end

end

describe DHashVips::IDHash do
  it "does not call distance3_ruby" do
    assert_equal :distance3, DHashVips::IDHash.method(:distance3).original_name
  end
end
