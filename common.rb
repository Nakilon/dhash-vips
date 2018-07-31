def download_and_keep image
  require "open-uri"
  FileUtils.mkdir_p dir = "images"
  "#{dir}/#{image}".tap do |filename|
    unless File.exist?(filename) && Digest::MD5.file(filename) == File.basename(filename, ".jpg")
      # example.metadata[:extra_failure_lines] << "copying image from web to #{filename}"
      open("https://storage.googleapis.com/dhash-vips.nakilon.pro/#{image}") do |link|
        File.open(filename, "wb") do |file|
          IO.copy_stream link, file
        end
      end
    end
  end
end
