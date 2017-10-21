Gem::Specification.new do |spec|
  spec.name          = "dhash-vips"
  spec.version       = (require_relative "lib/dhash-vips/version"; DHashVips::VERSION)
  spec.author        = "Victor Maslov"
  spec.email         = "nakilon@gmail.com"
  spec.summary       = "dHash and IDHash powered by Vips"
  spec.homepage      = "https://github.com/nakilon/dhash-vips"
  spec.license       = "MIT"

  spec.test_files    = ["spec"]
  spec.files         = `git ls-files -z`.split("\x0") - spec.test_files
  spec.require_path  = "lib"

  spec.add_dependency "ruby-vips"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-core"
  spec.add_development_dependency "dhash"
end
