require "minitest/autorun"

describe :test do
  it do
    FileUtils.move "idhash.bundle", "temp"
    begin
      require_relative "lib/dhash-vips"
      assert_equal :distance3_ruby, DHashVips::IDHash.method(:distance3).original_name
    ensure
      FileUtils.move "temp", "idhash.bundle"
    end
  end
end
