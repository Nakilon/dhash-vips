def download_and_keep image
  require "open-uri"
  FileUtils.mkdir_p dir = "images"
  "#{dir}/#{image}".tap do |filename|
    require "digest" if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.5.0")
    unless File.exist?(filename) && Digest::MD5.file(filename) == File.basename(filename, ".jpg")
      open("https://storage.googleapis.com/dhash-vips.nakilon.pro/#{image}") do |link|
        File.open(filename, "wb") do |file|
          IO.copy_stream link, file
        end
      end
    end
  end
end
