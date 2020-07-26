require "mkmf"

File.write "Makefile", dummy_makefile(?.).join
unless Gem::Platform.local.os == "darwin" && ENV["RBENV_ROOT"] && ENV["RBENV_VERSION"]
else
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.3.8") ||
     Gem::Version.new(RUBY_VERSION) > Gem::Version.new("2.4.9")
  else
    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.4")
    else
      append_cppflags "-DRUBY_EXPORT"
    end
    # https://github.com/rbenv/rbenv/issues/1199
    append_cppflags "-I#{Dir.glob("#{ENV["RBENV_ROOT"]}/sources/#{ENV["RBENV_VERSION"]}/ruby-*/").first}"
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

# Cases to check:
# 0. everything is ok
# `rm -rf idhash.o idhash.bundle idhash.so pkg && bundle exec rake install`
# `bundle exec rake -rdhash-vips -e "p DHashVips::IDHash.method(:distance3).source_location"` # => # ["/Users/nakilon/_/dhash-vips/lib/dhash-vips.rb", 32]  # currently falsely says that gem install failed idk why
# `rm -f idhash.o idhash.bundle idhash.so Makefile && ruby extconf.rb && make`
# `bundle exec rake -rdhash-vips -e "p DHashVips::IDHash.method(:distance3).source_location"` # => # ["/Users/nakilon/_/dhash-vips/lib/dhash-vips.rb", 53]
# 1. not macOS && rbenv
# 2. fail during append_cppflags
# 3. failed compilation
# 4. failed tests
