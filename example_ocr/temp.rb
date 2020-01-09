require "dhash-vips"

# Courier Menlo Monaco Tahoma
# Arial Verdana
# chars = %w{
#   DIN\ Condensed
#   Tahoma Arial
# }.flat_map do |font|
chars = [
  ["DIN Condensed, Bold", "/Library/Fonts/DIN Condensed Bold.ttf"],
].flat_map do |font, fontfile|
  FileUtils.mkdir_p "chars/#{font}"
  (?A..?Z).map do |char|
    filename = "chars/#{font}/#{char.ord}.png"
    Vips::Image.text(char, font: font, width: 100, height: 100).invert.write_to_file filename unless File.exist? filename
    # Vips::Image.text(char, fontfile: fontfile, font: font, width: 100, height: 100).invert.write_to_file filename unless File.exist? filename
    [DHashVips::IDHash.fingerprint(filename), char]
  end
end
exit


unless File.exist? "7dtd-menu.png"
  require "open-uri"
  File.binwrite "7dtd-menu.png", open("https://steamuserimages-a.akamaihd.net/ugc/787500339831956503/D337C857BBF0A62A998A7855DD21A5434F135300/", &:read)
end
image = Vips::Image.new_from_file("7dtd-menu.png").colourspace("b-w").invert

otsu = lambda do |image|
  require "unicode_plot"
  UnicodePlot.barplot((0..25).map(&:to_s), (image / 10).hist_find.to_a.flatten, width: 80).render STDOUT
  puts
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
bw.write_to_file "tempbw.png"
require "byebug"
# image.to_a[a..b]
# trim = threshold.find_trim threshold: 0, background: [255]
# p trim
# image = threshold.crop(*trim)
split_v = lambda do |image|
  image.invert.profile[1].to_a.each_with_index.chunk{ |row,| row != [[image.width]] }.select(&:first).map do |_, chunk|
    t = chunk.map(&:last)
    a, b = t[0], t[-1]
    [image.crop(0, a, image.width, b - a + 1), a, b]
  end
end
split_h = lambda do |image|
  image.invert.profile[0].to_a[0].each_with_index.chunk{ |row,| row != [image.height] }.select(&:first).map do |_, chunk|
    t = chunk.map(&:last)
    a, b = t[0], t[-1]
    [image.crop(a, 0, b - a + 1, image.height), a, b]
  end
end
split_v[bw].each_with_index do |(chunk, a, b), i|
  require "profile" if ENV["PROFILE"]
  # p [a, b]
  # splitted = split_v[bw.crop(0, a, image.width, b - a + 1).to_a.transpose]
  splitted = split_h[chunk]
  c, d = splitted[0][1], splitted[-1][2]
  p [a, b, c, d]
  t = image.>(otsu[image.crop(c, a, d - c + 1, b - a + 1)]).ifthenelse(255, 0)
  image.crop(c, a, d - c + 1, b - a + 1).write_to_file "temp.png"
  t.crop(c, a, d - c + 1, b - a + 1).write_to_file "temp#{i}.png"
  chunk, a, b = split_v[t].find{ |_, aa, bb| aa <= a && bb >= b || aa >= a && bb <= b }
  fail unless chunk
  # splitted = split_h[t.crop(0, a, image.width, b - a + 1).to_a.transpose]
  split_h[chunk].map do |chunk, c, d|
    # image.crop(c, a, d - c + 1, b - a + 1).write_to_file "temp3.png"
    # chunk.write_to_file "temp4.png"
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
      # FileUtils.copy temp.tap(&:rewind).path, "temp#{i}.png"
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
