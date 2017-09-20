require_relative "lib/dhash-vips"
Gem::Specification.new do |spec|
  spec.name          = "dhash-vips"
  spec.version       = (require_relative "lib/dhash-vips"; DhashVips::VERSION)
  spec.author        = "Victor Maslov aka Nakilon"
  spec.email         = "nakilon@gmail.com"
  spec.summary       = "dHash powered by Vips"
  spec.homepage      = "https://github.com/nakilon/dhash-vips"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0") - ["spec"]
  spec.test_files    = ["spec"]
  spec.require_path  = "lib"

  # spec.add_development_dependency "bundler", "~> 1.6"
  # spec.add_development_dependency "bundler", "~> 1.11"
  # spec.add_development_dependency "rake"
  # spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_dependency "rmagick"
end
