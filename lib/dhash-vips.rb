require "vips"

module DHashVips

  module IDHash
    extend self

    def distance3_ruby a, b
      ((a ^ b) & (a | b) >> 128).to_s(2).count "1"
    end
    begin
      require_relative "../idhash.#{Gem::Platform.local.os == "darwin" ? "bundle" : "o"}"
    rescue LoadError
      alias_method :distance3, :distance3_ruby
    else
      # we can't just do `defined? Bignum` because it's defined but deprecated (some internal CONST_DEPRECATED flag)
      if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.4")
        def distance3 a, b
          if a.is_a?(Bignum) && b.is_a?(Bignum)
            distance3_c a, b
          else
            distance3_ruby a, b
          end
        end
      else
        # https://github.com/ruby/ruby/commit/de2f7416d2deb4166d78638a41037cb550d64484#diff-16b196bc6bfe8fba63951420f843cfb4R10
        require "rbconfig/sizeof"
        FIXNUM_MAX = (1 << (8 * RbConfig::SIZEOF["long"] - 2)) - 1
        def distance3 a, b
          if a > FIXNUM_MAX && b > FIXNUM_MAX
            distance3_c a, b
          else
            distance3_ruby a, b
          end
        end
      end
    end
    def distance a, b
      size_a, size_b = [a, b].map do |x|
        x.size <= 32 ? 8 : 16
      end
      return distance3 a, b if [8, 8] == [size_a, size_b]
      fail "fingerprints were taken with different `power` param: #{size_a} and #{size_b}" if size_a != size_b
      ((a ^ b) & (a | b) >> 2 * size_a * size_a).to_s(2).count "1"
    end

  end

end
