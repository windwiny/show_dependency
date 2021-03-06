# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'show_dependency/version'

Gem::Specification.new do |spec|
  spec.name          = "show_dependency"
  spec.version       = ShowDependency::VERSION
  spec.authors       = ["windwiny"]
  spec.email         = ["windwiny.ubt@gmail.com"]
  spec.summary       = %q{create dependency digraph}
  spec.description   = %q{create dependency digraph.}
  spec.homepage      = "https://github.com/windwiny/show_dependency"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
