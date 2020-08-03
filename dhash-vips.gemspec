Gem::Specification.new do |spec|
  spec.name          = "dhash-vips"
  spec.version       = "0.1.1.3"
  spec.author        = "Victor Maslov"
  spec.email         = "nakilon@gmail.com"
  spec.summary       = "dHash and IDHash perceptual image hashing/fingerprinting"
  spec.homepage      = "https://github.com/nakilon/dhash-vips"
  spec.license       = "MIT"

  spec.require_path  = "lib"
  spec.extensions    = %w{ extconf.rb }
  spec.files         = %w{ extconf.rb Gemfile LICENSE.txt dhash-vips.gemspec idhash.c lib/dhash-vips-post-install-test.rb lib/dhash-vips.rb }
end
