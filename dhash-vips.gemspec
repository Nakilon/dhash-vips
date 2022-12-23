Gem::Specification.new do |spec|
  spec.name          = "dhash-vips"
  spec.version       = "0.2.3.0"
  spec.summary       = "dHash and IDHash perceptual image hashing/fingerprinting"
  # spec.homepage      = "https://github.com/nakilon/dhash-vips"

  spec.author        = "Victor Maslov"
  spec.email         = "nakilon@gmail.com"
  spec.license       = "MIT"

  spec.add_dependency "ruby-vips", "~> 2.0", "!= 2.1.0", "!= 2.1.1"

  spec.require_path  = "lib"
  spec.test_files    = %w{ test.rb }
  spec.extensions    = %w{ extconf.rb }
  spec.files         = %w{ extconf.rb Gemfile LICENSE.txt common.rb dhash-vips.gemspec idhash.c lib/dhash-vips-post-install-test.rb lib/dhash-vips.rb }
end
