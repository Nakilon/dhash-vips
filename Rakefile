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
