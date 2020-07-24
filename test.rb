require "minitest/autorun"

require "dhash-vips"

# TODO tests about `fingerprint(4)`

[
  [DHashVips::DHash, :hamming, :calculate, 2, 23, 18, 50, 4],
    # vips-8.9.1-Tue Jan 28 13:05:46 UTC 2020
    # [[0, 14, 26, 27, 31, 27, 32, 28, 43, 43, 34, 37, 37, 34, 35, 42],
    #  [14, 0, 28, 25, 39, 35, 32, 32, 43, 43, 38, 41, 41, 38, 37, 50],
    #  [26, 28, 0, 13, 35, 41, 28, 30, 41, 41, 36, 33, 35, 32, 27, 36],
    #  [27, 25, 13, 0, 36, 36, 31, 35, 40, 40, 33, 32, 42, 35, 26, 33],
    #  [31, 39, 35, 36, 0, 16, 33, 33, 40, 40, 31, 24, 28, 33, 40, 31],
    #  [27, 35, 41, 36, 16, 0, 41, 41, 38, 38, 23, 26, 24, 29, 34, 27],
    #  [32, 32, 28, 31, 33, 41, 0, 10, 27, 25, 38, 35, 37, 32, 23, 34],
    #  [28, 32, 30, 35, 33, 41, 10, 0, 27, 27, 34, 31, 37, 36, 27, 34],
    #  [43, 43, 41, 40, 40, 38, 27, 27, 0, 2, 35, 34, 30, 31, 28, 27],
    #  [43, 43, 41, 40, 40, 38, 25, 27, 2, 0, 35, 34, 30, 31, 28, 27],
    #  [34, 38, 36, 33, 31, 23, 38, 34, 35, 35, 0, 9, 23, 26, 29, 18],
    #  [37, 41, 33, 32, 24, 26, 35, 31, 34, 34, 9, 0, 22, 25, 30, 19],
    #  [37, 41, 35, 42, 28, 24, 37, 37, 30, 30, 23, 22, 0, 19, 26, 23],
    #  [34, 38, 32, 35, 33, 29, 32, 36, 31, 31, 26, 25, 19, 0, 21, 26],
    #  [35, 37, 27, 26, 40, 34, 23, 27, 28, 28, 29, 30, 26, 21, 0, 23],
    #  [42, 50, 36, 33, 31, 27, 34, 34, 27, 27, 18, 19, 23, 26, 23, 0]]
  [DHashVips::IDHash, :distance, :fingerprint, 6, 22, 23, 65, 0],
    # vips-8.9.1-Tue Jan 28 13:05:46 UTC 2020
    # [[0, 16, 32, 35, 57, 45, 51, 50, 48, 47, 54, 48, 60, 50, 47, 56],
    #  [16, 0, 30, 34, 58, 47, 55, 56, 47, 50, 57, 49, 62, 52, 52, 61],
    #  [32, 30, 0, 9, 47, 54, 45, 41, 65, 62, 42, 37, 51, 44, 49, 49],
    #  [35, 34, 9, 0, 54, 64, 42, 40, 57, 56, 48, 39, 50, 40, 41, 51],
    #  [57, 58, 47, 54, 0, 22, 43, 45, 64, 61, 48, 47, 35, 43, 47, 48],
    #  [45, 47, 54, 64, 22, 0, 53, 54, 55, 54, 40, 46, 39, 42, 43, 42],
    #  [51, 55, 45, 42, 43, 53, 0, 6, 33, 35, 52, 43, 46, 45, 44, 47],
    #  [50, 56, 41, 40, 45, 54, 6, 0, 38, 41, 53, 50, 48, 45, 41, 42],
    #  [48, 47, 65, 57, 64, 55, 33, 38, 0, 9, 51, 53, 47, 47, 41, 46],
    #  [47, 50, 62, 56, 61, 54, 35, 41, 9, 0, 51, 57, 50, 49, 44, 43],
    #  [54, 57, 42, 48, 48, 40, 52, 53, 51, 51, 0, 10, 33, 36, 38, 25],
    #  [48, 49, 37, 39, 47, 46, 43, 50, 53, 57, 10, 0, 27, 30, 37, 27],
    #  [60, 62, 51, 50, 35, 39, 46, 48, 47, 50, 33, 27, 0, 20, 23, 28],
    #  [50, 52, 44, 40, 43, 42, 45, 45, 47, 49, 36, 30, 20, 0, 35, 39],
    #  [47, 52, 49, 41, 47, 43, 44, 41, 41, 44, 38, 37, 23, 35, 0, 19],
    #  [56, 61, 49, 51, 48, 42, 47, 42, 46, 43, 25, 27, 28, 39, 19, 0]]
].each do |lib, dm, calc, min_similar, max_similar, min_not_similar, max_not_similar, bw_exceptional|

  describe lib do

    # these are false positive by idhash
    # 6d97739b4a08f965dc9239dd24382e96.jpg
    # 1b1d4bde376084011d027bba1c047a4b.jpg
    [
      [ %w{
        1d468d064d2e26b5b5de9a0241ef2d4b.jpg 92d90b8977f813af803c78107e7f698e.jpg
        309666c7b45ecbf8f13e85a0bd6b0a4c.jpg 3f9f3db06db20d1d9f8188cd753f6ef4.jpg
        679634ff89a31279a39f03e278bc9a01.jpg df0a3b93e9412536ee8a11255f974141.jpg
        54192a3f65bd03163b04849e1577a40b.jpg 6d32f57459e5b79b5deca2a361eb8c6e.jpg
        4b62e0eef58bfbc8d0d2fbf2b9d05483.jpg b8eb0ca91855b657f12fb3d627d45c53.jpg
        21cd9a6986d98976b6b4655e1de7baf4.jpg 9b158c0d4953d47171a22ed84917f812.jpg
        9c2c240ec02356472fb532f404d28dde.jpg fc762fa286489d8afc80adc8cdcb125e.jpg
        7a833d873f8d49f12882e86af1cc6b79.jpg ac033cf01a3941dd1baa876082938bc9.jpg
      }, min_similar, max_similar], # slightly silimar images
      [ %w{
        71662d4d4029a3b41d47d5baf681ab9a.jpg ad8a37f872956666c3077a3e9e737984.jpg
      }, bw_exceptional, bw_exceptional], # these are the same photo but of different size and colorspace
    ].each do |images, min, max|

      require "fileutils"
      require "digest"
      require "mll"

      require_relative "common"
      images = images.map &method(:download_and_keep)

      hashes = images.map &lib.method(calc)
      table = MLL::table[lib.method(dm), [hashes], [hashes]]

      require "pp"
      STDERR.puts ""
      PP.pp table, STDERR
      STDERR.puts ""

      hashes.size.times.to_a.repeated_combination(2) do |i, j|
        it do
          case
          when i == j
            assert_predicate table[i][j], :zero?
          when (j - i).abs == 1 && (i + j - 1) % 4 == 0
            # STDERR.puts [table[i][j], min, max].inspect
            assert_includes min..max, table[i][j]
          else
            # STDERR.puts [table[i][j], min_not_similar, max_not_similar].inspect
            assert_includes min_not_similar..max_not_similar, table[i][j]
          end
        end
      end

    end

  end

end
