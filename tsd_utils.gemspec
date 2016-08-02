# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tsd_utils/version'

Gem::Specification.new do |spec|
  spec.name          = 'tsd_utils'
  spec.version       = TsdUtils::VERSION
  spec.authors       = ['AVG Technologies && Lukas Svoboda']
  spec.email         = ['eng.op.autodev@avg.com', 'lukas.svoboda@gmail.com']

  spec.summary       = 'Basic handling of enqueue data and tsd format'
  spec.description   = 'Basic handling of enqueue data and tsd format'
  spec.homepage      = 'https://github.com/AVGTechnologies/'
  spec.license       = 'Apache-2.0'

  regex = %r{^(test|spec|features)/}
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(regex) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'mustache',       '~> 1.0'
  spec.add_dependency 'iniparse',       '~> 1.4.1'
  spec.add_dependency 'httparty',       '~> 0.13.7'
  spec.add_dependency 'gyoku',          '~> 1.0'
  spec.add_dependency 'activesupport',  '3.2.22'

  spec.add_development_dependency 'rubocop',        '~> 0.42'
  spec.add_development_dependency 'bundler',        '~> 1.10'
  spec.add_development_dependency 'json-compare',   '~> 0.1'
  spec.add_development_dependency 'rake',           '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-doc',        '>= 0.6.0'
  spec.add_development_dependency 'method_source',  '>= 0.8.2'
end
