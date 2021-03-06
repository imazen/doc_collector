# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'doc_collector/version'

Gem::Specification.new do |spec|
  spec.name          = "doc_collector"
  spec.version       = DocCollector::VERSION
  spec.authors       = ["Nathanael Jones"]
  spec.email         = ["nathanael.jones@gmail.com"]
  spec.summary       = %q{Collects documentation from multiple branches/repos and combines it }
  spec.description   = %q{Collects documentation from multiple branches/repos and combines it}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rugged"
  spec.add_dependency "hardwired"
  spec.add_dependency 'github-markdown', '~> 0.6.8'
  spec.add_dependency "rake"
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'erubis'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "minitest"
end
