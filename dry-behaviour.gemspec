# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dry/behaviour/version'

Gem::Specification.new do |spec|
  spec.name          = 'dry-behaviour'
  spec.version       = Dry::Behaviour::VERSION
  spec.authors       = ['Aleksei Matiushkin', 'Saverio Trioni', 'Kantox LTD']
  spec.email         = ['aleksei.matiushkin@kantox.com', 'saverio.trioni@kantox.com']

  spec.summary       = %(Tiny library inspired by Elixir protocol pattern.)
  spec.description   = %(This library makes it easy to declare protocols and use in in functional way.)
  spec.homepage      = 'https://kantox.com/'
  spec.license       = 'MIT'

  raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless spec.respond_to?(:metadata)

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = []
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'awesome_print', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'benchmark-ips', '~> 2.7'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
end
