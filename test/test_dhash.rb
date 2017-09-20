require 'minitest/autorun'
require 'dhash-vips'
require 'pp'

describe DhashVips do
  it 'should have similar hashes for low/high of same image' do
    hash1 = DhashVips.calculate(File.expand_path('../images/face-high.jpg', __FILE__))
    hash2 = DhashVips.calculate(File.expand_path('../images/face-low.jpg', __FILE__))

    assert DhashVips.hamming(hash1, hash2) < 3
  end

  it 'should have similar hashes for similar images' do
    hash1 = DhashVips.calculate(File.expand_path('../images/face-high.jpg', __FILE__))
    hash2 = DhashVips.calculate(File.expand_path('../images/face-with-nose.jpg', __FILE__))

    assert DhashVips.hamming(hash1, hash2) < 5
  end

  it 'should have identical hashes for identical images' do
    hash1 = DhashVips.calculate(File.expand_path('../images/face-high.jpg', __FILE__))
    hash2 = DhashVips.calculate(File.expand_path('../images/face-high.jpg', __FILE__))

    assert DhashVips.hamming(hash1, hash2) == 0
  end
end
