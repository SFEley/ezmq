# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "ezmq"
  spec.version       = File.read(File.join(File.dirname(__FILE__), 'ezmq.version')).chomp
  spec.authors       = ["Steve Eley"]
  spec.email         = ["sfeley@gmail.com"]
  spec.description   = %q{EZmq aims to be a simpler, more Rubyish wrapper for the fantastic ZeroMQ library. It abstracts away the C-style functions and low-level context and buffer management, and leaves a clean set of objects for sockets and messages.}
  spec.summary       = %q{Simple Ruby-like interface for ZeroMQ}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "ffi", "~> 1.9"
  spec.add_development_dependency "bundler", "~> 1.3"
end
