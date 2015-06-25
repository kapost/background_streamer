# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'background_streamer/version'

Gem::Specification.new do |spec|
  spec.name          = "background_streamer"
  spec.version       = BackgroundStreamer::VERSION
  spec.authors       = ["Raul E Rangel"]
  spec.email         = ["Raul@kapost.com"]
  spec.description   = %q{Stream Rack responses in the background!}
  spec.summary       = %q{Uses a thread pool to stream results in the background for long running requests.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rack", ">= 1.4"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
