unless Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.3.8")
  require "mkmf"
  File.write "Makefile", dummy_makefile(?.).join
  append_cppflags "-DRUBY_EXPORT" unless Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.4")
  create_makefile "idhash"
  File.write "Makefile", File.read("Makefile") + <<~HEREDOC
    .PHONY: post_install_test
    post_install_test: all
    \t$(RUBY) -r./lib/dhash-vips.rb ./lib/dhash-vips-post-install-test.rb
  HEREDOC
end

__END__

# this unlike using `rake -rbundler/gem_tasks` is building to current directory
#   that is vital to be able to require the native extension for benchmarking, etc.
$ ruby extconf.rb && make clean && make

# to test native extension
$ bundle exec ruby -e "require_relative 'lib/dhash-vips'; puts Gem.loaded_specs['dhash-vips'].version; p DHashVips::IDHash.method(:distance3).source_location"
# [".../dhash-vips.rb", 42] # if LoadError
# [".../dhash-vips.rb", 59] # if native

# to test the installation:
$ rake -rbundler/gem_tasks clean && rake -rbundler/gem_tasks install

Other cases to check:
1. not macOS && rbenv
2. fail during append_cppflags
3. failed compilation
4. failed tests
