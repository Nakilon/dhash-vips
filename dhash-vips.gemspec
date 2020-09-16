Gem::Specification.new do |spec|
  spec.name          = "dhash-vips"
  spec.version       = "0.1.1.3"
  spec.author        = "Victor Maslov"
  spec.email         = "nakilon@gmail.com"
  spec.summary       = "dHash and IDHash perceptual image hashing/fingerprinting"
  spec.homepage      = "https://github.com/nakilon/dhash-vips"
  spec.license       = "MIT"

  spec.require_path  = "lib"
  spec.test_files    = %w{ test.rb }
  spec.extensions    = %w{ extconf.rb }
  spec.files         = %w{ extconf.rb Gemfile LICENSE.txt common.rb dhash-vips.gemspec idhash.c lib/dhash-vips-post-install-test.rb lib/dhash-vips.rb }

  spec.add_dependency "ruby-vips", "~>2.0.16"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"

  spec.add_development_dependency "rmagick", "~>2.16"
  spec.add_development_dependency "phamilie"
  spec.add_development_dependency "dhash"

  spec.add_development_dependency "get_process_mem"

  spec.add_development_dependency "mll"
  spec.add_development_dependency "byebug"
end
