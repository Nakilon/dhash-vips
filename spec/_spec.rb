require "dhash-vips"

# TODO tests about `fingerprint(4)`
# TODO switch to Minitest?

[
  [DHashVips::DHash, :hamming, :calculate, 13, 16, 21, 42, 4],
    # [[0, 14, 26, 27, 27, 31, 28, 32],
    #  [14, 0, 28, 25, 35, 39, 34, 36],
    #  [26, 28, 0, 13, 41, 35, 42, 40],
    #  [27, 25, 13, 0, 36, 36, 37, 37],
    #  [27, 35, 41, 36, 0, 16, 21, 23],
    #  [31, 39, 35, 36, 16, 0, 21, 23],
    #  [28, 34, 42, 37, 21, 21, 0, 4],
    #  [32, 36, 40, 37, 23, 23, 4, 0]]
  [DHashVips::IDHash, :distance, :fingerprint, 9, 22, 30, 64, 0],
    # [[0, 17, 32, 35, 45, 57, 46, 45],
    #  [17, 0, 30, 35, 46, 58, 53, 51],
    #  [32, 30, 0, 9, 54, 47, 55, 55],
    #  [35, 35, 9, 0, 64, 54, 57, 57],
    #  [45, 46, 54, 64, 0, 22, 42, 40],
    #  [57, 58, 47, 54, 22, 0, 44, 41],
    #  [46, 53, 55, 57, 42, 44, 0, 0],
    #  [45, 51, 55, 57, 40, 41, 0, 0]]
].each do |lib, dm, calc, min_similar, max_similar, min_not_similar, max_not_similar, bw_exceptional|

describe lib do

  # these are false positive by idhash
  # 6d97739b4a08f965dc9239dd24382e96.jpg
  # 1b1d4bde376084011d027bba1c047a4b.jpg
  [
    [ %w{
      1d468d064d2e26b5b5de9a0241ef2d4b.jpg 92d90b8977f813af803c78107e7f698e.jpg
      309666c7b45ecbf8f13e85a0bd6b0a4c.jpg 3f9f3db06db20d1d9f8188cd753f6ef4.jpg
      df0a3b93e9412536ee8a11255f974141.jpg 679634ff89a31279a39f03e278bc9a01.jpg
    }, min_similar, max_similar], # slightly silimar images
    [ %w{
      71662d4d4029a3b41d47d5baf681ab9a.jpg ad8a37f872956666c3077a3e9e737984.jpg
    }, bw_exceptional, bw_exceptional], # these are the same photo but of different size and colorspace
  ].each do |images, min, max|

  example do
    require "fileutils"
    require "digest" if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.5.0")
    require "mll"

    require_relative "../common"
    images = images.map &method(:download_and_keep)

    hashes = images.map &described_class.method(calc)
    table = MLL::table[described_class.method(dm), [hashes], [hashes]]

    # require "pp"
    # STDERR.puts ""
    # pp table, STDERR
    # STDERR.puts ""

    aggregate_failures do
      hashes.size.times.to_a.repeated_combination(2) do |i, j|
        case
        when i == j
          expect(table[i][j]).to eq 0
        when (j - i).abs == 1 && (i + j - 1) % 4 == 0
          # STDERR.puts [table[i][j], min, max].inspect
          expect(table[i][j]).to be_between(min, max).inclusive
        else
          # STDERR.puts [table[i][j], min_not_similar, max_not_similar].inspect
          expect(table[i][j]).to be_between(min_not_similar, max_not_similar).inclusive
        end
      end

    end

  end

  end

  end

end
