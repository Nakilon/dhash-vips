require "dhash-vips"

describe DhashVips do

  require "tmpdir"
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

    example.metadata[:extra_failure_lines] = []
    FileUtils.mkdir_p dir = Dir.tmpdir + "/dhash-vips-spec"
    images.each do |image|
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

    hashes = images.map &DhashVips.method(:calculate)
    table = MLL::table[DhashVips.method(:hamming), [hashes], [hashes]]
    # require "pp"
    # pp table
    # [[0, 17, 29, 27, 22, 29],
    #  [17, 0, 30, 26, 33, 36],
    #  [29, 30, 0, 18, 39, 30],
    #  [27, 26, 18, 0, 35, 30],
    #  [22, 33, 39, 35, 0, 17],
    #  [29, 36, 30, 30, 17, 0]]

    hashes.size.times.to_a.combination(2) do |i, j|
      case
      when i == j
        expect(table[i][j]).to eq 0
      when (j - i).abs == 1 && (i + j - 1) % 4 == 0
        expect(table[i][j]).to be > 0
        expect(table[i][j]).to be < 19
      else
        expect(table[i][j]).to be > 21
      end
    end
  end

end
