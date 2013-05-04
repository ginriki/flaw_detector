require 'mkmf'
create_makefile("insns_ext", "insns/#{RUBY_VERSION[0..2]}")
