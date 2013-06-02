# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "flaw_detector/version"

Gem::Specification.new do |s|
  s.name        = "flaw_detector"
  s.version     = FlawDetector::VERSION
  s.authors     = ["Rikiya Ayukawa"]
  s.email       = ["dbc.ginriki@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{The tool to detect code's flaw with static analysis}
  s.description = %q{The tool detects code's flaw, which should be fixed, with static analysis of RubyVM bytecode. Therefore, it works for only ruby 1.9.x or 2.0.x .}

  s.rubyforge_project = "flaw detector"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.extensions                = ["ext/insns_ext/extconf.rb"]
  s.required_ruby_version = "> 1.9.0"

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
