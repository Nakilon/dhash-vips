require "dhash-vips"

# Courier Menlo Monaco Tahoma
chars = %w{
  Arial Verdana
}.flat_map do |font|
  FileUtils.mkdir_p "chars/#{font}"
  (?A..?Z).map do |char|
    filename = "chars/#{font}/#{char.ord}.png"
    Vips::Image.text(char, font: font, width: 100, height: 100).invert.write_to_file filename unless File.exist? filename
    [DHashVips::IDHash.fingerprint(filename), char]
  end
end


unless File.exist? "7dtd-menu.png"
  require "open-uri"
  File.binwrite "7dtd-menu.png", open("https://steamuserimages-a.akamaihd.net/ugc/787500339831956503/D337C857BBF0A62A998A7855DD21A5434F135300/", &:read)
end
image = Vips::Image.new_from_file("7dtd-menu.png").colourspace("b-w").invert

otsu = lambda do |image|
  require "unicode_plot"
  # UnicodePlot.barplot((0..25).map(&:to_s), (image / 10).hist_find.to_a.flatten, width: 80).render STDOUT
  # puts
  histData = image.hist_find.to_a.flatten
  total = histData.sum
  sum = 0
  256.times do |t|
    sum += t * histData[t]
  end
  sumB = 0
  wB = 0
  wF = 0
  varMax = 0
  threshold = 0
  256.times do |t|
     wB += histData[t]
     next if (wB == 0)
     wF = total - wB
     break if (wF == 0)
     sumB += t * histData[t]
     mB = sumB / wB
     mF = (sum - sumB) / wF
     varBetween = wB * wF * (mB - mF) * (mB - mF)
     if varBetween > varMax
        varMax = varBetween
        threshold = t
     end
  end
  p threshold
end
bw = image.>(otsu[image]).ifthenelse(255, 0)
bw.write_to_file "temp1.png"
require "byebug"
# image.to_a[a..b]
# trim = threshold.find_trim threshold: 0, background: [255]
# p trim
# image = threshold.crop(*trim)
split = lambda do |array|
  array.each_with_index.chunk{ |row,| row.any?{ |c,| c < 255 } }.select(&:first).map do |_, chunk|
    t = chunk.map(&:last)
    [chunk.map(&:first), t[0], t[-1]]
  end
end
split[bw.to_a].each do |chunk, a, b|
  require "profile" if ENV["PROFILE"]
  # p [a, b]
  # splitted = split[bw.crop(0, a, image.width, b - a + 1).to_a.transpose]
  splitted = split[chunk.transpose]
  c, d = splitted[0][1], splitted[-1][2]
  p [a, b, c, d]
  t = image.>(otsu[image.crop(c, a, d - c + 1, b - a + 1)]).ifthenelse(255, 0)
  t.crop(c, a, d - c + 1, b - a + 1).write_to_file "temp2.png"
# byebug
  chunk, a, b = split[t.to_a].find{ |_, aa, bb| aa <= a && bb >= b || aa >= a && bb <= b }
  fail unless chunk
  # splitted = split[t.crop(0, a, image.width, b - a + 1).to_a.transpose]
  split[chunk.transpose].map do |chunk, c, d|
    image.crop(c, a, d - c + 1, b - a + 1).write_to_file "temp3.png"
    Vips::Image.new_from_array(chunk.transpose).write_to_file "temp4.png"
    # exit
    # p [a, b]
    # exit
    # image.write_to_file "temp.png"
    # byebug
    require "tempfile"
    temp = Tempfile.new [File.basename(File.expand_path __dir__()), ".png"]
    fingerprint = begin
      # image.crop(a, 0, b - a + 1, image.height).write_to_file "temp.png"
      temp.write image.crop(c, a, d - c + 1, b - a + 1).write_to_buffer(".png")
      FileUtils.copy temp.tap(&:rewind).path, "temp.png"
# exit
      DHashVips::IDHash.fingerprint temp.tap(&:rewind).path
    ensure
      temp.tap(&:unlink).close
    end
    chars.min_by{ |f,| DHashVips::IDHash.distance f, fingerprint }.last
  end.join.inspect.tap &method(:puts)
# byebug
  # trim = image.find_trim threshold: 0, background: [255]
  # image.crop(*trim).write_to_file "temp.png"
  # image.to_a[a..b]
  # require "byebug"
  # byebug
  break if ENV["PROFILE"]
end



__END__


split[Vips::Image.new_from_file("7dtd-menu.png").colourspace("b-w").invert.flatten.to_a].each do |line|
  split[line.transpose].map do |char|
  end.join.tap &method(:puts)
end
