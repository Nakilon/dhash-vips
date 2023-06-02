Gem::Specification.new do |spec|
  spec.name          = "dhash-vips"
  spec.version       = "0.2.3.0"
  spec.summary       = "dHash and IDHash perceptual image hashing/fingerprinting"
  spec.metadata      = {"source_code_uri" => "https://github.com/nakilon/dhash-vips"}

  spec.author        = "Victor Maslov aka Nakilon"
  spec.email         = "nakilon@gmail.com"
  spec.license       = "MIT"

  spec.add_dependency "ruby-vips", "~> 2.0", "!= 2.1.0", "!= 2.1.1"

  spec.require_path  = "lib"
  spec.extensions    = %w{ extconf.rb }
  spec.files         = %w{ LICENSE.txt dhash-vips.gemspec lib/dhash-vips.rb idhash.c lib/dhash-vips-post-install-test.rb } + spec.extensions
end
