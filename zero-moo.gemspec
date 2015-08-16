# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zero/moo/version'

Gem::Specification.new do |spec|
  spec.name          = "zero-moo"
  spec.version       = Zero::Moo::VERSION
  spec.authors       = ["Tim Förster"]
  spec.email         = ["github@mailserver.1n3t.de"]

  spec.summary       = %q{ZMQ based communication util}
  spec.homepage      = "https://github.com/timmyArch/zero-moo"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  
  spec.add_dependency "ffi-rzmq", '2.0.4'
end
