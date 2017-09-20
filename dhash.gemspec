# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dhash/version'

Gem::Specification.new do |spec|
  spec.name          = "dhash"
  spec.version       = Dhash::VERSION
  spec.authors       = ["Alex MacCaw"]
  spec.email         = ["info@eribium.org"]
  spec.summary       = %q{Calculate Dhash on images}
  spec.homepage      = "https://github.com/maccman/dhash"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_dependency 'rmagick'
end
