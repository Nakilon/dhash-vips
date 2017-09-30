Gem::Specification.new do |spec|
  spec.name          = "dhash-vips"
  spec.version       = (require_relative "lib/dhash-vips/version"; DHashVips::VERSION)
  spec.author        = "Victor Maslov"
  spec.email         = "nakilon@gmail.com"
  spec.summary       = "dHash powered by Vips"
  spec.homepage      = "https://github.com/nakilon/dhash-vips"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0") - ["spec"]
  spec.test_files    = ["spec"]
  spec.require_path  = "lib"

  spec.add_dependency "ruby-vips"
  spec.add_dependency "mll"

  spec.add_development_dependency "dhash"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-core"
end
