# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'version'

Gem::Specification.new do |spec|
  spec.name = "jmdict"
  spec.version = JMDict::VERSION
  spec.authors = ["Justin Jeffress"]
  spec.email  = ["sleepydeveloper@gmail.com"]

  spec.description = "Convert JMDict xml file to json"
  spec.summary = "JMDict xml to json"
  spec.homepage = "http://github.com/sleepydeveloper"
  spec.license = "MIT"

  spec.files = %w( README.md jmdict.gemspec ) + Dir['lib/**/*.rb'] + Dir["misc/.*[a-zA-Z_]"]
  spec.executables << 'jmsplit'
  #spec.test_files = []
  spec.require_paths = ["lib", "misc"]

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'nokogiri', '~> 1.5'

end
