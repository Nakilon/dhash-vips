require "mkmf"

File.write "Makefile", dummy_makefile(?.).join

unless Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.3.8")
  if ruby_source_dir = if File.directory? "/ruby"
    "-I/ruby"  # for Github Actions: docker (currently disabled) and benchmark
  elsif ENV["RBENV_ROOT"] && ENV["RBENV_VERSION"] && File.exist?(t = "#{ENV["RBENV_ROOT"]}/sources/#{ENV["RBENV_VERSION"]}/ruby-#{ENV["RBENV_VERSION"]}/bignum.c")   # https://github.com/rbenv/rbenv/issues/1199
    "-I#{File.dirname t}"
  end
    append_cppflags ruby_source_dir
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
end

__END__

to test: $ rake clean && rake install

$ ruby extconf.rb && make clean && make
$ ruby -rdhash-vips -e "p DHashVips::IDHash.method(:distance3).source_location"
# [".../dhash-vips.rb", 32] # if LoadError
# [".../dhash-vips.rb", 52] # if native (or 42 with Ruby<2.4)

Other cases to check:
1. not macOS && rbenv
2. fail during append_cppflags
3. failed compilation
4. failed tests
