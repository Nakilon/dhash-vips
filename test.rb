require "minitest/autorun"

require "dhash-vips"

# TODO tests about `fingerprint(4)`

[
  [DHashVips::DHash, :hamming, :calculate, 10, 16, 21, 42, 4],
    # [[0, 14, 26, 27, 31, 27, 32, 28],
    #  [14, 0, 28, 25, 39, 35, 32, 32],
    #  [26, 28, 0, 13, 35, 41, 28, 30],
    #  [27, 25, 13, 0, 36, 36, 31, 35],
    #  [31, 39, 35, 36, 0, 16, 33, 33],
    #  [27, 35, 41, 36, 16, 0, 41, 41],
    #  [32, 32, 28, 31, 33, 41, 0, 10],
    #  [28, 32, 30, 35, 33, 41, 10, 0]]
  [DHashVips::IDHash, :distance, :fingerprint, 6, 22, 30, 64, 0],
    # [[0, 17, 32, 35, 57, 45, 51, 50],
    #  [17, 0, 30, 35, 58, 46, 54, 55],
    #  [32, 30, 0, 9, 47, 54, 45, 41],
    #  [35, 35, 9, 0, 54, 64, 42, 40],
    #  [57, 58, 47, 54, 0, 22, 43, 45],
    #  [45, 46, 54, 64, 22, 0, 53, 54],
    #  [51, 54, 45, 42, 43, 53, 0, 6],
    #  [50, 55, 41, 40, 45, 54, 6, 0]]
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
      }, min_similar, max_similar], # slightly silimar images
      [ %w{
        71662d4d4029a3b41d47d5baf681ab9a.jpg ad8a37f872956666c3077a3e9e737984.jpg
      }, bw_exceptional, bw_exceptional], # these are the same photo but of different size and colorspace
    ].each do |images, min, max|

      require "fileutils"
      require "digest" if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.5.0")
      require "mll"

      require_relative "common"
      images = images.map &method(:download_and_keep)

      hashes = images.map &lib.method(calc)
      table = MLL::table[lib.method(dm), [hashes], [hashes]]

      # require "pp"
      # STDERR.puts ""
      # PP.pp table, STDERR
      # STDERR.puts ""

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
