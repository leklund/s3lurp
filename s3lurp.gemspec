# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 's3lurp/version'

Gem::Specification.new do |spec|
  spec.name          = "s3lurp"
  spec.version       = S3lurp::VERSION
  spec.authors       = ["Lukas Eklund"]
  spec.email         = ["leklund@gmail.com"]
  spec.description   = %q{s3lurp - Browser uploads direct to Amazon S3}
  spec.summary       = %q{ActionView::Helper to generate a form tag for direct uploads to S3. Configurable via ENV or yml}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'aws-sdk'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'actionpack'
  spec.add_development_dependency 'activesupport'
end
