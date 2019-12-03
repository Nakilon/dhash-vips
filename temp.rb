# (byebug) hashes[0]
# 27362028616592833077810614538336061650596602259623245623188871925927275101952
# (byebug) hashes[1]
# 57097733966917585112089915289446881218887831888508524872740133297073405558528
# (byebug) DHashVips::IDHash.distance hashes[0], hashes[1]
# 17

# $ bundle exec ruby extconf.rb && rm -f idhash.o && make && ruby -r./idhashdist ./temp.rb
# require_relative "idhashdist"

a, b = 27362028616592833077810614538336061650596602259623245623188871925927275101952, 57097733966917585112089915289446881218887831888508524872740133297073405558528
f = ->a,b{ ((a ^ b) & (a | b) >> 128).to_s(2).count(?1) }

p as = [a.to_s(16).rjust(64,?0)].pack("H*").unpack("N*")
p bs = [b.to_s(16).rjust(64,?0)].pack("H*").unpack("N*")
puts as.zip(bs)[0,4].map{ |i,j| (i | j).to_s(2).rjust(32, ?0) }.zip \
     as.zip(bs)[4,4].map{ |i,j| (i ^ j).to_s(2).rjust(32, ?0) }
# p [a.to_s(16)].pack("H*").unpack("N*").map{ |_| _.to_s(2).rjust(32, ?0) }
# p [b.to_s(16)].pack("H*").unpack("N*").map{ |_| _.to_s(2).rjust(32, ?0) }
p dist a, b
p f[a, b]

# __END__

s = [0, 1, 1<<63, (1<<63)+1, (1<<64)-1].each do |_|
  # p [_.to_s(16).rjust(64,?0)].pack("H*").unpack("N*").map{ |_| _.to_s(2).rjust(32, ?0) }
end
ss = s.repeated_permutation(4).map do |s1, s2, s3, s4|
  ((s1 << 192) + (s2 << 128) + (s3 << 64) + s4).tap do |_|
    # p [_.to_s(16).rjust(64,?0)].pack("H*").unpack("N*").map{ |_| _.to_s(2).rjust(32, ?0) }
  end
end
ss.product ss do |s1, s2|
  next unless s1.is_a?(Bignum) && s2.is_a?(Bignum)
  # p [s1.size, s2.size, s1.to_s(2).size, s2.to_s(2).size]
  # p s1.to_s(2), s2.to_s(2)
  # p f[s1, s2], dist(s1, s2)
  unless f[s1, s2] == dist(s1, s2)
    p [s1, s2]
    p [s1.to_s(16).rjust(64,?0)].pack("H*").unpack("N*").map{ |_| _.to_s(2).rjust(32, ?0) }
    p [s2.to_s(16).rjust(64,?0)].pack("H*").unpack("N*").map{ |_| _.to_s(2).rjust(32, ?0) }
    p [f[s1, s2], dist(s1, s2)]
    fail
  end
end

t = Time.now
2000000.times do
  dist a, b
end
p Time.now - t

# __END__

def ff a, b
  ((a ^ b) & ((a | b) >> 128)).to_s(2).count(?1)
end
t = Time.now
1000000.times do
  ff a, b
end
p Time.now - t

t = Time.now
1000000.times do
  dist a + rand(1000009), b + rand(1000009)
end
p Time.now - t

def ff a, b
  ((a ^ b) & ((a | b) >> 128)).to_s(2).count(?1)
end
t = Time.now
1000000.times do
  ff a + rand(1000009), b + rand(1000009)
end
p Time.now - t
