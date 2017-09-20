require 'minitest/autorun'
require 'dhash'
require 'pp'

describe Dhash do
  it 'should have similar hashes for low/high of same image' do
    hash1 = Dhash.calculate(File.expand_path('../images/face-high.jpg', __FILE__))
    hash2 = Dhash.calculate(File.expand_path('../images/face-low.jpg', __FILE__))

    assert Dhash.hamming(hash1, hash2) < 3
  end

  it 'should have similar hashes for similar images' do
    hash1 = Dhash.calculate(File.expand_path('../images/face-high.jpg', __FILE__))
    hash2 = Dhash.calculate(File.expand_path('../images/face-with-nose.jpg', __FILE__))

    assert Dhash.hamming(hash1, hash2) < 5
  end

  it 'should have identical hashes for identical images' do
    hash1 = Dhash.calculate(File.expand_path('../images/face-high.jpg', __FILE__))
    hash2 = Dhash.calculate(File.expand_path('../images/face-high.jpg', __FILE__))

    assert Dhash.hamming(hash1, hash2) == 0
  end
end