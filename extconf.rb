require "mkmf"

# append_cppflags "-O3 -I#{Gem.loaded_specs["bit_utils"].full_gem_path}/ext"
append_cppflags "-I/Users/nakilon/.rbenv/sources/2.3.8/ruby-2.3.8/"

dir_config "idhashdist"
create_makefile "idhashdist"
