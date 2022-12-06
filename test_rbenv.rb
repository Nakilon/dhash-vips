require "open3"
e = lambda do |_|
  (string, status) = Open3.capture2e _.tap &method(:puts)
  unless status.exitstatus.zero?
    puts string
    abort "exitstatus = #{status.exitstatus}"
  end
end
for version in Dir.entries("#{ENV["RBENV_ROOT"]}/sources").grep(/\A(2\.[3-9]|3\.\d)\.\d\z/).sort.reverse.uniq{ |_| _[0,3] }.reverse.drop(1).each
  e["set -e && eval \"$(rbenv init -)\" && rbenv shell #{version} && gem uninstall -a dhash-vips && ruby extconf.rb && make clean && make"]
  e["set -e && eval \"$(rbenv init -)\" && rbenv shell #{version} && bundle install && bundle exec ruby test.rb && bundle exec ruby test_LoadError.rb"]
end
puts "OK"
