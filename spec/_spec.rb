require "dhash-vips"

describe DhashVips do

  require "tmpdir"
  require "fileutils"
  require "open-uri"
  require "digest"
  require "mll"
  # require "pp"
  example do

    # 60b219c68366519903383fd1a929ab2f.jpg
    # c2b7bbc1859a0f610f816e68d126709f.jpg
    # 9c2c240ec02356472fb532f404d28dde.jpg
    # fc762fa286489d8afc80adc8cdcb125e.jpg

    images = %w{
      1d468d064d2e26b5b5de9a0241ef2d4b.jpg
      92d90b8977f813af803c78107e7f698e.jpg
      309666c7b45ecbf8f13e85a0bd6b0a4c.jpg
      3f9f3db06db20d1d9f8188cd753f6ef4.jpg
    }

    FileUtils.mkdir_p dir = Dir.tmpdir + "/dhash-vips-spec"
    images.map do |image|
      "#{dir}/#{image}".tap do |filename|
        open("https://storage.googleapis.com/dhash-vips.nakilon.pro/#{image}") do |link|
          puts "copying image from web to #{filename}"
          File.open(filename, "wb") do |file|
            IO.copy_stream link, file
          end
        end unless File.exist?(filename) && Digest::MD5.file(filename) == File.basename(filename, ".jpg")
      end
    end

    hashes = images.map &DhashVips.method(:calculate)
    table = MLL::table[DhashVips.method(:hamming), [hashes], [hashes]]
    # [[0, 17, 29, 27], [17, 0, 30, 26], [29, 30, 0, 18], [27, 26, 18, 0]]

    hashes.size.times.to_a.combination(2) do |i, j|
      case
      when i == j
        expect(table[i][j]).to eq 0
      when (j - i).abs == 1 && (i + j - 1) % 4 == 0     # 1st image is similar to 2nd and 3rd is miliar to 4th
        expect(table[i][j]).to be > 0
        expect(table[i][j]).to be < 19
      else
        expect(table[i][j]).to be > 25
      end
    end
  end

end
