# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'allpay/version'

Gem::Specification.new do |spec|
  spec.name          = "allpay-web-service"
  spec.version       = AllpayWebService::VERSION
  spec.authors       = ["Calvert"]
  spec.email         = [""]

  spec.summary       = "Basic API client for Allpay credit card Web Service."
  spec.description   = ""
  spec.homepage      = "https://github.com/CalvertYang/allpay-web-service"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nori", "~> 2.6"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 11.2"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "nokogiri", "~> 1.6.8"

  spec.required_ruby_version = ">= 2.1.5"
end
