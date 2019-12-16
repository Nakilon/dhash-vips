Gem::Specification.new do |spec|
  spec.name          = "dhash-vips"
  spec.version       = "0.1.0.0"
  spec.author        = "Victor Maslov"
  spec.email         = "nakilon@gmail.com"
  spec.summary       = "dHash and IDHash powered by Vips"
  spec.homepage      = "https://github.com/nakilon/dhash-vips"
  spec.license       = "MIT"

  spec.test_files    = %w{ test.rb }
  spec.files         = `git ls-files -z`.split("\x0") - spec.test_files - %w{ .gitignore }
  spec.require_path  = "lib"
  spec.extensions    = %w{ extconf.rb }

  spec.add_dependency "ruby-vips", "~>2.0.17"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "get_process_mem"

  spec.add_development_dependency "rmagick", "~>2.16"
  spec.add_development_dependency "phamilie"
  spec.add_development_dependency "dhash"

  spec.add_development_dependency "mll"
  spec.add_development_dependency "byebug"
end
