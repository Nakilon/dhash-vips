STDOUT.sync = true

require "bundler/gem_tasks"


task :default => %w{ spec }

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new :spec do |t|
  t.verbose = false
end


visualize_hash = lambda do |hash|
  puts hash.to_s(2).rjust(64, ?0).gsub(/(?<=.)/, '\0 ').scan(/.{16}/)
end

desc "Compare how Vips and ImageMagick resize images to 9x8"
task :compare_pixelation do |_|
  require_relative "lib/dhash-vips"
  require "dhash"

  ARGV.drop(1).each do |arg|
    FileUtils.mkdir_p "compare_pixelation/#{File.dirname arg}"

    puts filename = "compare_pixelation/#{arg}.dhash-vips.png"
    DHashVips::DHash.pixelate(arg, 8).
      colourspace(:srgb).       # otherwise we may get `Vips::Error` `RGB color space not permitted on grayscale PNG` when the image was already bw
      write_to_file filename
    visualize_hash.call DHashVips::DHash.calculate arg

    puts filename = "compare_pixelation/#{arg}.dhash.png"
    Magick::Image.read(arg).first.quantize(256, Magick::Rec601LumaColorspace, Magick::NoDitherMethod, 8).resize!(9, 8).
      write filename
    visualize_hash.call Dhash.calculate arg
  end
end

desc "Compare how Vips resizes image to 9x8 with different kernels"
task :compare_kernels do |_|
  require_relative "lib/dhash-vips"
  # require "dhash"

  %i{ nearest linear cubic lanczos2 lanczos3 }.each do |kernel|
    hashes = ARGV.drop(1).map do |arg|
      puts arg
      DHashVips::DHash.calculate(arg, 8, kernel).tap &visualize_hash
    end
    puts "kernel: #{kernel}, distance: #{DHashVips::DHash.hamming *hashes}"
  end
end

# ./ruby `rbenv which rake` compare_matrixes
desc "Compare the quality of Dhash, DHashVips::DHash and DHashVips::IDHash -- run it only after `rake test`"
task :compare_matrices do |_|
  require "dhash"
  require_relative "lib/dhash-vips"
  require "mll"
  [[Dhash, :hamming], [DHashVips::DHash, :hamming], [DHashVips::IDHash, :distance]].each do |m, dm|
    puts "\n#{m}"
    hashes = %w{
      71662d4d4029a3b41d47d5baf681ab9a.jpg
      ad8a37f872956666c3077a3e9e737984.jpg

      6d97739b4a08f965dc9239dd24382e96.jpg
      1b1d4bde376084011d027bba1c047a4b.jpg

      1d468d064d2e26b5b5de9a0241ef2d4b.jpg
      92d90b8977f813af803c78107e7f698e.jpg

      309666c7b45ecbf8f13e85a0bd6b0a4c.jpg
      3f9f3db06db20d1d9f8188cd753f6ef4.jpg
      df0a3b93e9412536ee8a11255f974141.jpg
      679634ff89a31279a39f03e278bc9a01.jpg
    }.map{ |filename| m.calculate "images/#{filename}" }
    table = MLL::table[m.method(dm), [hashes], [hashes]]
    # require "pp"
    # pp table
    array = Array.new(5){ [] }
    hashes.size.times.to_a.repeated_combination(2) do |i, j|
      array[i == j ? 0 : (j - i).abs == 1 && (i + j - 1) % 4 == 0 ? [i, j] == [0, 1] ? 1 : [i, j] == [2, 3] ? 2 : 3 : 4].push table[i][j]
    end
    # p array.map &:sort
    puts "Absolutely the same image: #{array[0].minmax.join ".."}"
    puts "Complex B/W and the same but colorful: #{array[1][0]}"
    puts "Similar images: #{array[3].minmax.join ".."}"
    puts "Different images: #{[*array[2], *array[4]].minmax.join ".."}"
  end
end

# ruby -c Rakefile && rm -f ab.png && rake compare_images -- fc762fa286489d8afc80adc8cdcb125e.jpg 9c2c240ec02356472fb532f404d28dde.jpg 2>/dev/null && ql ab.png
# rm -f ab.png && ./ruby `rbenv which rake` compare_images -- 6d97739b4a08f965dc9239dd24382e96.jpg 1b1d4bde376084011d027bba1c047a4b.jpg 2>/dev/null && ql ab.png
desc "Visualizes the IDHash difference measurement between two images"
task :compare_images do |_|
  abort "there should be two image filenames passed as arguments" unless ARGV.size == 3
  require_relative "lib/dhash-vips"
  ha, hb = ARGV.drop(1).map &DHashVips::IDHash.method(:calculate)
  puts "distance: #{DHashVips::IDHash.distance ha, hb}"

  a, b = ARGV.drop(1).map do |filename|
    image = Vips::Image.new_from_file filename
    image = image.resize(8.fdiv(image.width), vscale: 8.fdiv(image.height)).colourspace("b-w").
                           resize(100, vscale: 100, kernel: :nearest).colourspace("srgb")
  end
  fail unless a.width == b.width && a.height == b.height

  ai = ha >> 128
  ad = ha - (ai << 128)
  bi = hb >> 128
  bd = hb - (bi << 128)

  n = 0
  [[a, ad, ai], [b, bd, bi]].each do |image, xd, xi|
    127.downto(0).each do |i|
      if i > 63
        y, x = (127 - i).divmod 8
      else
        x, y = (63 - i).divmod 8
      end
      x = (image.width  * (x + 0.5) / 8).round
      y = (image.height * (y + 0.5) / 8).round
      if i > 63
        (x-2..x+2).map do |x| [
          [x,  y                                        , x, (y + image.height / 16 - 1) % image.height],
          [x, (y + image.height / 16 + 1) % image.height, x, (y + image.height /  8    ) % image.height],
        ] end
      else
        (y-2..y+2).map do |y| [
          [ x                                      , y, (x + image.width / 16 - 1) % image.width, y],
          [(x + image.width / 16 + 1) % image.width, y, (x + image.width /  8    ) % image.width, y],
        ] end
      end.each do |coords1, coords2|
        n += 1
        image = image.draw_line (1 - xd[i]) * 255, *coords1
        image = image.draw_line      xd[i]  * 255, *coords2
      end if ai[i] + bi[i] > 0 && ad[i] != bd[i]
      cx, cy = if i > 63
        [x, y + 20]
      else
        [x + 20, y]
      end
      image = image.draw_circle      xd[i]  * 255, cx, cy, 11, fill: true if xi[i] > 0
      image = image.draw_circle (1 - xd[i]) * 255, cx, cy, 10, fill: true if xi[i] > 0
    end
    image
  end
  puts "distance: #{n / 10}"
  puts "(above should be equal if raketask works correcly)"

  a.join(b, :horizontal, shim: 15).write_to_file "ab.png"
end

# ./ruby `rbenv which rake` compare_speed
desc "Benchmarks Dhash, DHashVips::DHash and DHashVips::IDHash"
task :compare_speed do
  require "dhash"
  require_relative "lib/dhash-vips"

  filenames = %w{
    71662d4d4029a3b41d47d5baf681ab9a.jpg
    ad8a37f872956666c3077a3e9e737984.jpg
    1d468d064d2e26b5b5de9a0241ef2d4b.jpg
    92d90b8977f813af803c78107e7f698e.jpg
    309666c7b45ecbf8f13e85a0bd6b0a4c.jpg
    3f9f3db06db20d1d9f8188cd753f6ef4.jpg
    df0a3b93e9412536ee8a11255f974141.jpg
    679634ff89a31279a39f03e278bc9a01.jpg
  }.flat_map do |filename|
    image = Vips::Image.new_from_file "images/#{filename}"
    [0, 1, 2, 3].map do |a|
      "benchmark/#{a}_#{filename}".tap do |filename|
        next if File.exist? filename
        FileUtils.mkdir_p "benchmark"
        image.rot(a).write_to_file filename
      end
    end
  end

  require "benchmark"
  puts "load and calculate the fingerprint:"
  hashes = []
  Benchmark.bm 18 do |bm|
    [Dhash, DHashVips::DHash, DHashVips::IDHash].each do |m|
      bm.report m do
        hashes.push filenames.map &m.method(:calculate)
      end
    end
  end
  puts "measure the distance (1000 times):"
  Benchmark.bm 18 do |bm|
    [[Dhash, :hamming], [DHashVips::DHash, :hamming], [DHashVips::IDHash, :distance]].zip(hashes) do |(m, dm), hs|
      bm.report m do
        hs.product hs do |h1, h2|
          1000.times{ m.send dm, h1, h2 }
        end
      end
    end
  end

end
