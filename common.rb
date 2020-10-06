def download_and_keep image   # returns path
  require "open-uri"
  require "digest"
  File.join(FileUtils.mkdir_p(File.expand_path "images", __dir__()).first, image).tap do |path|
    open("https://storage.googleapis.com/dhash-vips.nakilon.pro/#{image}") do |link|
      File.open(path, "wb") do |file|
        IO.copy_stream link, file
      end
    end unless File.exist?(path) && Digest::MD5.file(path) == File.basename(image, ".jpg")
  end
end

def download_if_needed path
  require "open-uri"
  require "digest"
  FileUtils.mkdir_p File.dirname path
  open("https://storage.googleapis.com/dhash-vips.nakilon.pro/#{File.basename path}") do |link|
    File.open(path, "wb"){ |file| IO.copy_stream link, file }
  end unless File.exist?(path) && Digest::MD5.file(path) == File.basename(path, File.extname(path))
  path
end
