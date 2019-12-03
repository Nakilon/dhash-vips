require "mkmf"

# append_cppflags "-O3 -I#{Gem.loaded_specs["bit_utils"].full_gem_path}/ext"

append_cppflags "-I#{Dir.glob("#{`rbenv root`.chomp}/sources/#{`rbenv version-name`.chomp}/*/").first}" rescue abort "failed to compile"

create_makefile "idhash"
