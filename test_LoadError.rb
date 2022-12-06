require "minitest/autorun"

describe :test do
  it do
    FileUtils.move "idhash.bundle", "temp"
    begin
      require_relative "lib/dhash-vips"
      DHashVips::IDHash.stub :distance3_ruby, ->*{ :expectation } do
        assert_equal :expectation, DHashVips::IDHash.distance3((2<<256)-1, (2<<256)-1)
      end
    ensure
      FileUtils.move "temp", "idhash.bundle"
    end
  end
end
