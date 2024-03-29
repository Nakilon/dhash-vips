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
unless File.exist? "monotype-arial.png"
  require "open-uri"
  File.binwrite "monotype-arial.png", open("http://gems.nakilon.pro.storage.yandexcloud.net/dhash-vips/monotype-arial.png", &:read)
end

split = lambda do |array|
  array.chunk{ |row| row.any?{ |c,| c < 255 } }.select(&:first).map(&:last)
end
split[Vips::Image.new_from_file("monotype-arial.png").colourspace("b-w").flatten.to_a].each do |line|
  split[line.transpose].map do |char|
    require "tempfile"
    temp = Tempfile.new [File.basename(File.expand_path __dir__()), ".png"]
    fingerprint = begin
      temp.write Vips::Image.new_from_array(char.transpose).write_to_buffer(".png")
      DHashVips::IDHash.fingerprint temp.tap(&:rewind).path
    ensure
      temp.tap(&:unlink).close
    end
    chars.min_by{ |f,| DHashVips::IDHash.distance f, fingerprint }.last
  end.join.tap &method(:puts)
end
