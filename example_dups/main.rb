require "dhash-vips"
Dir.chdir ENV["TEST"] || "/images"

pattern = %w{ *.jp*g *.png }
pairs = Dir.glob(pattern).tap do |_|
  puts "\n#{pattern} images found: #{_.size}\n\n"
end.sort.map{ |f| [DHashVips::IDHash.fingerprint(f), f] }.
  combination(2).map{ |(h1, f1), (h2, f2)| [DHashVips::IDHash.distance(h1, h2), f1, f2] }

[
  ["very similar", 0..14],
  ["similar", 15..19],
  ["probably similar", 20..24],
].each do |category, range|
  pairs.select{ |dist,| range.include? dist }.tap do |_|
    puts "#{category} image pairs: #{_.size}\n\n"
  end.each do |dist, f1, f2|
    puts "\tdistance: #{dist}\n\t#{f1}\n\t#{f2}\n\n"
  end
end
