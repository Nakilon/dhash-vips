STDOUT.sync = true
require "pp"



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

desc "Compare the quality of Dhash, Phamilie, DHashVips::DHash, DHashVips::IDHash -- run it only after `rake test`"
task :compare_quality do |_|
  require "dhash"
  require "phamilie"
  phamilie = Phamilie.new
  require_relative "lib/dhash-vips"
  require "mll"

  puts MLL::grid.call( [
    ["", "The same image:", "'Jordan Voth case':", "Similar images:", "Different images:"],
    *[
      [Dhash, :calculate, :hamming],
      [phamilie, :fingerprint, :distance, nil, 0],
      [DHashVips::DHash, :calculate, :hamming],
      [DHashVips::IDHash, :fingerprint, :distance],
      [DHashVips::IDHash, :fingerprint, :distance, 4],
    ].map do |m, calc, dm, power, ii|
      require_relative "common"
      hashes = %w{
        71662d4d4029a3b41d47d5baf681ab9a.jpg ad8a37f872956666c3077a3e9e737984.jpg

        1b1d4bde376084011d027bba1c047a4b.jpg 6d97739b4a08f965dc9239dd24382e96.jpg

        1d468d064d2e26b5b5de9a0241ef2d4b.jpg 92d90b8977f813af803c78107e7f698e.jpg
        309666c7b45ecbf8f13e85a0bd6b0a4c.jpg 3f9f3db06db20d1d9f8188cd753f6ef4.jpg
        679634ff89a31279a39f03e278bc9a01.jpg df0a3b93e9412536ee8a11255f974141.jpg
        54192a3f65bd03163b04849e1577a40b.jpg 6d32f57459e5b79b5deca2a361eb8c6e.jpg
        4b62e0eef58bfbc8d0d2fbf2b9d05483.jpg b8eb0ca91855b657f12fb3d627d45c53.jpg
        21cd9a6986d98976b6b4655e1de7baf4.jpg 9b158c0d4953d47171a22ed84917f812.jpg
      }.map(&method(:download_and_keep)).map{ |filename| [filename, m.public_send(calc, filename, *power)] }
      table = MLL::table[m.method(dm), [hashes.map{|_|_[ii||1]}], [hashes.map{|_|_[ii||1]}]]
      report = Struct.new(:same, :bw, :sim, :not_sim).new [], [], [], []
      hashes.size.times.to_a.repeated_combination(2) do |i, j|
        report[
          case
          when i == j                            ; :same
          when [i, j] == [0, 1]                  ; :bw
          when i > 3 && i + 1 == j && i % 2 == 0 ; :sim
          else                                   ; :not_sim
          end
        ].push table[i][j]
      end
      [
        "#{m.is_a?(Module) ? m : m.class}#{" #{power}" if power}",
        report.same.   minmax.join(".."),
        report.bw[0],
        report.sim.    minmax.join(".."),
        report.not_sim.minmax.join(".."),
      ]
    end,
  ].transpose, spacings: [2, 0], alignment: :right )
end

# ruby -c Rakefile && rm -f ab.png && rake compare_images -- fc762fa286489d8afc80adc8cdcb125e.jpg 9c2c240ec02356472fb532f404d28dde.jpg 2>/dev/null && ql ab.png
# rm -f ab.png && ./ruby `rbenv which rake` compare_images -- 6d97739b4a08f965dc9239dd24382e96.jpg 1b1d4bde376084011d027bba1c047a4b.jpg 2>/dev/null && ql ab.png
desc "Visualizes the IDHash difference measurement between two images"
task :compare_images do |_|
  abort "there should be two image filenames passed as arguments (and optionally the `power`)" unless (3..4) === ARGV.size
  abort "the optional argument should be either 3 or 4" unless [3, 4].include?(power = (ARGV[3] || 3).to_i)
  task ARGV.last do ; end
  require_relative "lib/dhash-vips"
  ha, hb = ARGV[1, 2].map{ |filename| DHashVips::IDHash.fingerprint(filename, power) }
  puts "distance: #{DHashVips::IDHash.distance ha, hb}"
  size = 2 ** power
  shift = 2 * size * size
  ai = ha >> shift
  ad = ha - (ai << shift)
  bi = hb >> shift
  bd = hb - (bi << shift)

  a, b = ARGV[1, 2].map do |filename|
    image = Vips::Image.new_from_file filename
    image = image.resize(size.fdiv(image.width), vscale: size.fdiv(image.height)).colourspace("b-w").
                  resize(100, vscale: 100, kernel: :nearest).colourspace("srgb")
  end
  fail unless a.width == b.width && a.height == b.height

  _127 = shift - 1
  _63 = size * size - 1
  n = 0
  width = a.width
  height = a.height

  Vips::Operation.class_eval do
    old_initialize = instance_method :initialize
    define_method :initialize do |value|
      old_initialize.bind(self).(value).tap do
        self.instance_variable_set "@operation_name", value
      end
    end
    old_set = instance_method :set
    define_method :set do |*args|
      args[1].instance_variable_set "@operation_name", self.instance_variable_get("@operation_name") if args.first == "image"
      old_set.bind(self).(*args)
    end
  end
  Vips::Image.class_eval do
    def copy
      return self if caller.first.end_with?("/gems/ruby-vips-2.0.9/lib/vips/operation.rb:148:in `set'") &&
                     %w{ draw_line draw_circle }.include?(instance_variable_get "@operation_name")
      method_missing :copy
    end
  end

  require "get_process_mem"
  a, b = [[a, ad, ai], [b, bd, bi]].map do |image, xd, xi|
    _127.downto(0).each_with_index do |i, ii|
      mem = GetProcessMem.new(Process.pid).mb
      abort ">1000mb of memory consumed" if 1000 < mem
      if i > _63
        y, x = (_127 - i).divmod size
      else
        x, y = (_63 - i).divmod size
      end
      x = (width  * (x + 0.5) / size).round
      y = (height * (y + 0.5) / size).round
      if i > _63
        (x-2..x+2).map do |x| [
          [x,  y                                  , x, (y + height / size / 2 - 1) % height],
          [x, (y + height / size / 2 + 1) % height, x, (y + height / size        ) % height],
        ] end
      else
        (y-2..y+2).map do |y| [
          [ x                                , y, (x + width / size / 2 - 1) % width, y],
          [(x + width / size / 2 + 1) % width, y, (x + width / size        ) % width, y],
        ] end
      end.each do |coords1, coords2|
        n += 1
        image = image.draw_line (1 - xd[i]) * 255, *coords1
        image = image.draw_line      xd[i]  * 255, *coords2
      end if ai[i] + bi[i] > 0 && ad[i] != bd[i]
      cx, cy = if i > _63
        [x, y + 30]
      else
        [x + 30, y]
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
  require "phamilie"
  phamilie = Phamilie.new
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
  Benchmark.bm 19 do |bm|
    [
      [Dhash, :calculate],
      [phamilie, :fingerprint],
      [DHashVips::DHash, :calculate],
      [DHashVips::IDHash, :fingerprint],
      [DHashVips::IDHash, :fingerprint, 4],
    ].each do |m, calc, power|
      bm.report "#{m.is_a?(Module) ? m : m.class} #{power}" do
        hashes.push filenames.map{ |filename| m.send calc, filename, *power }
      end
    end
  end
  hashes[-1, 1] = hashes[-2, 2]     # for `distance` and `distance3` we use the same hashes
  puts "\nmeasure the distance (1000 times):"
  Benchmark.bm 29 do |bm|
    [
      [Dhash, :hamming],
      [phamilie, :distance, nil, 1],
      [DHashVips::DHash, :hamming],
      [DHashVips::IDHash, :distance],
      [DHashVips::IDHash, :distance3],
      [DHashVips::IDHash, :distance, 4],
    ].zip(hashes) do |(m, dm, power, ii), hs|
      bm.report "#{m.is_a?(Module) ? m : m.class} #{dm} #{power}" do
        _ = [hs, filenames][ii || 0]
        _.product _ do |h1, h2|
          1000.times{ m.public_send dm, h1, h2 }
        end
      end
    end
  end

end
