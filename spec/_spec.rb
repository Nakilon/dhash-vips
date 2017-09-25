require "dhash-vips"

require "pp"

[
  [DHashVips::DHash, 17, 18, 22, 39],
    # [[0, 17, 29, 27, 22, 29, 30, 29],
    #  [17, 0, 30, 26, 33, 36, 37, 36],
    #  [29, 30, 0, 18, 39, 30, 39, 36],
    #  [27, 26, 18, 0, 35, 30, 35, 34],
    #  [22, 33, 39, 35, 0, 17, 28, 23],
    #  [29, 36, 30, 30, 17, 0, 33, 30],
    #  [30, 37, 39, 35, 28, 33, 0, 5],
    #  [29, 36, 36, 34, 23, 30, 5, 0]]
  [DHashVips::IDHash, 15, 23, 28, 64],
    # [[0, 16, 30, 32, 46, 58, 43, 43],
    #  [16, 0, 28, 28, 47, 59, 46, 47],
    #  [30, 28, 0, 15, 53, 49, 53, 52],
    #  [32, 28, 15, 0, 56, 53, 61, 64],
    #  [46, 47, 53, 56, 0, 23, 43, 45],
    #  [58, 59, 49, 53, 23, 0, 44, 44],
    #  [43, 46, 53, 61, 43, 44, 0, 0],
    #  [43, 47, 52, 64, 45, 44, 0, 0]]
  # [DHashVips::IDHash, 14, 14, 21],
].each do |lib, min_similar, max_similar, min_not_similar, max_not_similar|

describe lib do

  # require "tmpdir"
  require "fileutils"
  require "open-uri"
  require "digest"
  require "mll"
  example do |example|

    images = %w{
      1d468d064d2e26b5b5de9a0241ef2d4b.jpg
      92d90b8977f813af803c78107e7f698e.jpg
      309666c7b45ecbf8f13e85a0bd6b0a4c.jpg
      3f9f3db06db20d1d9f8188cd753f6ef4.jpg
      df0a3b93e9412536ee8a11255f974141.jpg
      679634ff89a31279a39f03e278bc9a01.jpg
    }   # these images a consecutive pairs of slightly (but enough for nice asserts) silimar images
    bw1, bw2 = %w{
      71662d4d4029a3b41d47d5baf681ab9a.jpg
      ad8a37f872956666c3077a3e9e737984.jpg
    }   # these is the same photo but of different size and bw

    example.metadata[:extra_failure_lines] = []
    FileUtils.mkdir_p dir = "images"
    *images, bw1, bw2 = [*images, bw1, bw2].map do |image|
      "#{dir}/#{image}".tap do |filename|
        unless File.exist?(filename) && Digest::MD5.file(filename) == File.basename(filename, ".jpg")
          example.metadata[:extra_failure_lines] << "copying image from web to #{filename}"
          open("https://storage.googleapis.com/dhash-vips.nakilon.pro/#{image}") do |link|
            File.open(filename, "wb") do |file|
              IO.copy_stream link, file
            end
          end
        end
      end
    end

    hashes = [*images, bw1, bw2].map &described_class.method(:calculate)
    table = MLL::table[described_class.method(:hamming), [hashes], [hashes]]

    # require "pp"
    # pp table
    # abort

    aggregate_failures do
      hashes.size.times.to_a.repeated_combination(2) do |i, j|
        case
        when i == j
          expect(table[i][j]).to eq 0
        when (j - i).abs == 1 && (i + j - 1) % 4 == 0
          if [i, j] == [hashes.size - 2, hashes.size - 1]
            if described_class == DHashVips::DHash
              expect(table[i][j]).to be == 5
            else
              expect(table[i][j]).to eq 0
            end
          else
            expect(table[i][j]).to be_between(min_similar, max_similar).inclusive
          end
        else
          expect(table[i][j]).to be_between(min_not_similar, max_not_similar).inclusive
        end
      end

    end

  end

end

end
