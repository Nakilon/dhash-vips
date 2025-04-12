require "mkmf"

File.write "Makefile", dummy_makefile(?.).join

unless Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.3.8")
  append_cppflags "-DRUBY_EXPORT" unless Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.4")
  create_makefile "idhash"
  # Why this hack?
  # 1. Because I want to use Ruby and ./idhash.bundle for tests, not C.
  # 2. Because I don't want to bother users with two gems instead of one.
  File.write "Makefile", <<~HEREDOC + File.read("Makefile")
    .PHONY: test
    test: all
    \t$(RUBY) -r./lib/dhash-vips.rb ./lib/dhash-vips-post-install-test.rb
  HEREDOC
end

__END__

# this unlike using rake is building to current directory
#   that is vital to be able to require the native extension for benchmarking, etc.
$ ruby extconf.rb && make clean && make

# to test the installation:
$ rake clean && rake install

$ ruby -e "require 'dhash-vips'; p DHashVips::IDHash.method(:distance3).source_location"  # using -r makes bundler mad
# [".../dhash-vips.rb", 32] # if LoadError
# [".../dhash-vips.rb", 52] # if native (or 42 with Ruby<2.4)

Other cases to check:
1. not macOS && rbenv
2. fail during append_cppflags
3. failed compilation
4. failed tests
