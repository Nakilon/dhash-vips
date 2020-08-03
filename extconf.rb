require "mkmf"

File.write "Makefile", dummy_makefile(?.).join
unless Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.3.8")
  if ENV["RBENV_ROOT"] && ENV["RBENV_VERSION"]
    append_cppflags "-I#{Dir.glob("#{ENV["RBENV_ROOT"]}/sources/#{ENV["RBENV_VERSION"]}/ruby-*/").first}"
  else
    append_cppflags "-I/ruby/"
  end
  append_cppflags "-DRUBY_EXPORT" unless Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.4")
  create_makefile "idhash"
  File.write "Makefile", <<~HEREDOC + File.read("Makefile")
    .PHONY: test
    test: all
    \t$(RUBY) -r./lib/dhash-vips.rb ./lib/dhash-vips-post-install-test.rb
  HEREDOC
end

# rm -f idhash.o idhash.bundle idhash.so Makefile && ruby extconf.rb && make
# bundle exec rake -rdhash-vips -e "p DHashVips::IDHash.method(:distance3).source_location"
