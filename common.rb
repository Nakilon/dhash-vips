def download_if_needed path
  require "open-uri"
  require "digest"
  FileUtils.mkdir_p File.dirname path
  URI("http://gems.nakilon.pro.storage.yandexcloud.net/dhash-vips/#{File.basename path}".tap do |url|
    puts "downloading #{path} from #{url}"
  end).open do |link|
    File.open(path, "wb"){ |file| IO.copy_stream link, file }
  end unless File.exist?(path) && Digest::MD5.file(path) == File.basename(path, File.extname(path))
  path
end
