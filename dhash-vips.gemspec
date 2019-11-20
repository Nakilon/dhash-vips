Gem::Specification.new do |spec|
  spec.name          = "dhash-vips"
  spec.version       = "0.0.6.1"
  spec.author        = "Victor Maslov"
  spec.email         = "nakilon@gmail.com"
  spec.summary       = "dHash and IDHash powered by Vips"
  spec.homepage      = "https://github.com/nakilon/dhash-vips"
  spec.license       = "MIT"

  spec.test_files    = %w{ spec }
  spec.files         = `git ls-files -z`.split("\x0") - spec.test_files
  spec.require_path  = "lib"

  spec.add_dependency "ruby-vips", "2.0.12"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-core"
  spec.add_development_dependency "get_process_mem"
  spec.add_development_dependency "mll"

  spec.add_development_dependency "rmagick", "~>2.16"
  spec.add_development_dependency "dhash"
end
