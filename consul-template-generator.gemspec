# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'consul/template/generator/version'

Gem::Specification.new do |spec|
  spec.name          = 'consul-template-generator'
  spec.version       = Consul::Template::Generator::VERSION
  spec.authors       = ['Brian Oldfield']
  spec.email         = ['brian.oldfield@socrata.com']
  spec.summary       = %q{Wrapper around consul template which uploads renterd templates to consul's KV store}
  spec.description   = %q{When using complex consul-template templates or distributing them across many hosts, you run the risk of DoSing your consul cluster.  Using consul-template-generator you can instead delegate the watching/rendering of templates to a single host and have downstream clients instead use a simple consul-template KV watch to retrieve the template and write it to disk.}
  spec.homepage      = 'http://github.com/boldfield/consul-template-generator'
  spec.license       = 'Apache'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/consul-template-generator}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.3'
  spec.add_development_dependency 'simplecov', '~> 0.10'
  spec.add_development_dependency 'simplecov-console', '~> 0.2'
  spec.add_development_dependency 'webmock', '~> 1.21'
  spec.add_development_dependency 'rack', '~> 1.6'
  spec.add_dependency 'diffy', '~> 3.0'
  spec.add_dependency 'diplomat', '~> 0.13'
  spec.add_dependency 'popen4', '~> 0.1'
end
