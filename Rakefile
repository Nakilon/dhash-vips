require "bundler/gem_tasks"

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
      DHashVips::DHash.calculate(arg, 8, kernel).tap(&visualize_hash)
    end
    puts "kernel: #{kernel}, distance: #{DHashVips::DHash.hamming(*hashes)}"
  end
end

require_relative "common"

desc "Compare the quality of gems"
# in this test we want to know not that photos are the same but rather that they are from the same photosession
task :compare_quality do
  require "dhash"
  require "phamilie"
  phamilie = Phamilie.new
  require_relative "lib/dhash-vips"
  require "mll"

  puts MLL::grid.call( [
    ["", "The same image:", "'Jordan Voth case':", "Similar images:", "Different images:", "1/FMI^2 =", "FP, FN =", "optimal threshold"],
    *[
      [Dhash, :calculate, :hamming],
      [phamilie, :fingerprint, :distance, nil, 0],
      [DHashVips::DHash, :calculate, :hamming],
      [DHashVips::IDHash, :fingerprint, :distance],
      [DHashVips::IDHash, :fingerprint, :distance, 4],
    ].map do |m, calc, dm, power, ii|
      hashes = %w{
        71662d4d4029a3b41d47d5baf681ab9a.jpg ad8a37f872956666c3077a3e9e737984.jpg

        1b1d4bde376084011d027bba1c047a4b.jpg 6d97739b4a08f965dc9239dd24382e96.jpg

        1d468d064d2e26b5b5de9a0241ef2d4b.jpg 92d90b8977f813af803c78107e7f698e.jpg
        309666c7b45ecbf8f13e85a0bd6b0a4c.jpg 3f9f3db06db20d1d9f8188cd753f6ef4.jpg
        679634ff89a31279a39f03e278bc9a01.jpg df0a3b93e9412536ee8a11255f974141.jpg
        54192a3f65bd03163b04849e1577a40b.jpg 6d32f57459e5b79b5deca2a361eb8c6e.jpg
        4b62e0eef58bfbc8d0d2fbf2b9d05483.jpg b8eb0ca91855b657f12fb3d627d45c53.jpg
        21cd9a6986d98976b6b4655e1de7baf4.jpg 9b158c0d4953d47171a22ed84917f812.jpg
        9c2c240ec02356472fb532f404d28dde.jpg fc762fa286489d8afc80adc8cdcb125e.jpg
        7a833d873f8d49f12882e86af1cc6b79.jpg ac033cf01a3941dd1baa876082938bc9.jpg
      }.map{ |_| "compare_quality_images/#{_}" }.
        each(&method(:download_if_needed)).
        map{ |_| [_, m.public_send(calc, _, *power)] }
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
      p report
      _min, max = [*report.sim, *report.not_sim].minmax
      fmi, fp, fn, tr = (0..max+1).map do |b|
        fp = report.not_sim.count{ |_| _ < b }
        tp = (report.sim + report.bw).count{ |_| _ < b }
        fn = (report.sim + report.bw).count{ |_| _ >= b }
        [((tp + fp) * (tp + fn)).fdiv(tp * tp), fp, fn, b]
      end.reject{ |_,| _.nan? }.min_by(&:first)
      [
        "#{m.is_a?(Module) ? m.name.split("::").last : m.class}#{"(#{power})" if power}",
        report.same.   minmax.join(".."),
        report.bw[0],
        report.sim.    minmax.join(".."),
        report.not_sim.minmax.join(".."),
        fmi.round(3),
        [fp, fn],
        tr,
      ]
    end,
  ].transpose, spacings: [1.5, 0], alignment: :right )
end

# ruby -c Rakefile && rm -f ab.png && rake compare_images -- fc762fa286489d8afc80adc8cdcb125e.jpg 9c2c240ec02356472fb532f404d28dde.jpg 2>/dev/null && ql ab.png
# rm -f ab.png && ./ruby `rbenv which rake` compare_images -- 6d97739b4a08f965dc9239dd24382e96.jpg 1b1d4bde376084011d027bba1c047a4b.jpg 2>/dev/null && ql ab.png
# bundle exec rake compare_images[1b1d4bde376084011d027bba1c047a4b.jpg,6d97739b4a08f965dc9239dd24382e96.jpg]
desc "Visualizes the IDHash difference measurement between two images"
task :compare_images do |_, args|
  abort "there should be two image filenames passed as arguments (and optionally the `power`)" unless (2..3) === args.extras.size
  abort "the optional argument should be either 3 or 4" unless [3, 4].include?(power = (args.extras[2] || 3).to_i)
  require_relative "lib/dhash-vips"
  ha, hb = args.extras.map{ |filename| DHashVips::IDHash.fingerprint(filename, power) }
  puts "distance: #{DHashVips::IDHash.distance ha, hb}"
  size = 2 ** power
  shift = 2 * size * size
  ai = ha >> shift
  ad = ha - (ai << shift)
  bi = hb >> shift
  bd = hb - (bi << shift)

  a, b = args.extras.map do |filename|
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
  puts "(above should be equal if raketask works correctly)"

  a.join(b, :horizontal, shim: 15).write_to_file "ab.png"
  puts "the ab.png is ready"
end

desc "Benchmark speed of Dhash, DHashVips::DHash, DHashVips::IDHash and Phamilie"
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
  puts "load the image and calculate the fingerprint:"
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

  # for `distance`, `distance3_ruby` and `distance3_c` we use the same hashes
  # this array manipulation converts [1, 2, 3, 4, 5] into [1, 2, 3, 4, 4, 4, 5]
  hashes[-1, 1] = hashes[-2, 2]
  hashes[-1, 1] = hashes[-2, 2]

  puts "\nmeasure the distance (32*32*2000 times):"
  Benchmark.bm 32 do |bm|
    [
      [Dhash, :hamming],
      [phamilie, :distance, nil, 1],
      [DHashVips::DHash, :hamming],
      [DHashVips::IDHash, :distance],
      [DHashVips::IDHash, :distance3_ruby],
      [DHashVips::IDHash, :distance3_c],
      [DHashVips::IDHash, :distance, 4],
    ].zip(hashes) do |(m, dm, power, ii), hs|
      bm.report "#{m.is_a?(Module) ? m : m.class} #{dm} #{power}" do
        _ = [hs, filenames][ii || 0]
        _.product _ do |h1, h2|
          2000.times{ m.public_send dm, h1, h2 }
        end
      end
    end
  end

end

desc "Benchmarks everything about gems"
task :benchmark do
  # TODO: better handling of the need to `ruby extconf.rb && make clean && make`
  system "ruby -v"
  puts ""

  system "apt-cache show libvips42 2>/dev/null | grep Version"
  system "vips -v 2>/dev/null"
  system "apt-cache show libmagickwand-dev 2>/dev/null | grep Version"
  system "identify -version 2>/dev/null | /usr/bin/head -1"
  system "identify-6 -version 2>/dev/null | /usr/bin/head -1"
  system "sysctl -n machdep.cpu.brand_string 2>/dev/null"
  system "cat /proc/cpuinfo 2>/dev/null | grep 'model name' | uniq"
  puts ""

  require_relative "lib/dhash-vips"
  puts "gem ruby-vips: #{Gem.loaded_specs["ruby-vips"].version}"
  puts ""

  puts "gem rmagick: #{Gem.loaded_specs["rmagick"].version}"
  require "dhash"    ; puts "gem dhash: #{Gem.loaded_specs["dhash"].source}"
  require "phamilie" ; puts "gem phamilie: #{Gem.loaded_specs["phamilie"].version}"
  phamilie = Phamilie.new
  require "mini_magick"
  require "phash"    ; puts "gem phash-rb: #{Gem.loaded_specs["phash-rb"].source}"
  puts ""

  filenames = [
     %w{ benchmark_images/0/6d97739b4a08f965dc9239dd24382e96.jpg },
     %w{ benchmark_images/1/7a833d873f8d49f12882e86af1cc6b79.jpg benchmark_images/1/ac033cf01a3941dd1baa876082938bc9.jpg },
     %w{ benchmark_images/2/9c2c240ec02356472fb532f404d28dde.jpg benchmark_images/2/fc762fa286489d8afc80adc8cdcb125e.jpg },
     %w{ benchmark_images/3/21cd9a6986d98976b6b4655e1de7baf4.jpg benchmark_images/3/9b158c0d4953d47171a22ed84917f812.jpg },
     %w{ benchmark_images/4/4b62e0eef58bfbc8d0d2fbf2b9d05483.jpg benchmark_images/4/b8eb0ca91855b657f12fb3d627d45c53.jpg },
     %w{ benchmark_images/5/54192a3f65bd03163b04849e1577a40b.jpg benchmark_images/5/6d32f57459e5b79b5deca2a361eb8c6e.jpg },
     %w{ benchmark_images/6/679634ff89a31279a39f03e278bc9a01.jpg benchmark_images/6/df0a3b93e9412536ee8a11255f974141.jpg },
     %w{ benchmark_images/7/309666c7b45ecbf8f13e85a0bd6b0a4c.jpg benchmark_images/7/3f9f3db06db20d1d9f8188cd753f6ef4.jpg },
     %w{ benchmark_images/8/1d468d064d2e26b5b5de9a0241ef2d4b.jpg benchmark_images/8/92d90b8977f813af803c78107e7f698e.jpg },
     %w{ benchmark_images/9/1b1d4bde376084011d027bba1c047a4b.jpg },
     %w{ benchmark_images/10/71662d4d4029a3b41d47d5baf681ab9a.jpg benchmark_images/10/ad8a37f872956666c3077a3e9e737984.jpg }
  ].each{ |g| g.each(&method(:download_if_needed)) }
  puts "image groups sizes: #{filenames.map &:size}"
  require "benchmark"

  puts "step 1 / 3 (fingerprinting)"
  hashes = []
  bm1 = [
    Benchmark.realtime{ hashes.push filenames.flatten.map{ |filename| ::Dhash.calculate filename } },
    Benchmark.realtime{ hashes.push filenames.flatten.map{ |filename| phamilie.fingerprint filename; filename } },
    Benchmark.realtime{ hashes.push filenames.flatten.map{ |filename| ::DHashVips::IDHash.fingerprint filename } },
    Benchmark.realtime{ hashes.push filenames.flatten.map{ |filename| ::DHashVips::IDHash.fingerprint filename } },
    Benchmark.realtime{ hashes.push filenames.flatten.map{ |filename| ::DHashVips::DHash.calculate filename } },
    Benchmark.realtime{ hashes.push filenames.flatten.map{ |filename| ::Phash::Image.new(filename).tap &:fingerprint } },
  ]

  puts "step 2 / 3 (comparing fingerprints)"
  combs = filenames.flatten.size ** 2
  n = 10_000_000_000_000 / combs / filenames.flatten.map(&File.method(:size)).inject(:+)
  bm2 = [
    Benchmark.realtime{ hashes[0].product(hashes[0]){ |h1, h2| n.times{ ::Dhash.hamming h1, h2 } } },
    Benchmark.realtime{ hashes[1].product(hashes[1]){ |p1, p2| n.times{ phamilie.distance p1, p2 } } },
    Benchmark.realtime{ hashes[2].product(hashes[2]){ |h1, h2| n.times{ ::DHashVips::IDHash.distance3 h1, h2 } } },
    Benchmark.realtime{ hashes[3].product(hashes[3]){ |h1, h2| n.times{ ::DHashVips::IDHash.distance3_ruby h1, h2 } } },
    Benchmark.realtime{ hashes[4].product(hashes[4]){ |h1, h2| n.times{ ::DHashVips::DHash.hamming h1, h2 } } },
    Benchmark.realtime{ hashes[5].product(hashes[5]){ |h1, h2| n.times{ h1.distance_from h2 } } },
  ]

  puts "step 3 / 3 (looking for the best threshold)"
  bm3 = [
    ["Dhash", ->a,b{ ::Dhash.hamming a, b }],
    ["Phamilie", ->a,b{ phamilie.distance a, b }],
    ["IDHash default", ->a,b{ ::DHashVips::IDHash.distance3 a, b }],
    ["IDHash Ruby", ->a,b{ ::DHashVips::IDHash.distance3 a, b }],
    ["DHash", ->a,b{ ::DHashVips::DHash.hamming a, b }],
    ["Phash", ->a,b{ a.distance_from b }],
  ].zip(hashes).map do |(name, f), hs|
    report = Struct.new(:same, :sim, :not_sim).new [], [], []
    hs.size.times.to_a.repeated_combination(2) do |i, j|
      report[
        case
        when i == j                                                           ; :same
        when File.split(File.split(filenames.flatten[i]).first).last ==
             File.split(File.split(filenames.flatten[j]).first).last && i < j ; :sim
        else                                                                  ; :not_sim
        end
      ].push f[hs[i], hs[j]]
    end
    # p report
    min, max = [*report.sim, *report.not_sim].minmax
    p [name, min, max]
    fmi, fp, fn = (min..max+1).map do |b|
      fp = report.not_sim.count{ |_| _ < b }
      tp = report.sim.count{ |_| _ < b }
      fn = report.sim.count{ |_| _ >= b }
      [((tp + fp) * (tp + fn)).fdiv(tp * tp), fp, fn]
    end.reject{ |_,| _.nan? }.min_by(&:first)
    [name, fmi]
  end

  require "mll"
  puts MLL::grid.call %w{ \  Fingerprint Compare 1/FMI^2 }.zip(*[
    bm3.map(&:first),
    *[bm1, bm2, bm3.map(&:last)].map{ |bm| bm.map{ |_| "%.3f" % _ } }
  ].transpose).transpose, spacings: [1.5, 0], alignment: :right
  puts "(lower numbers are better)"
end
