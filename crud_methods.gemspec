# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'crud_methods/version'

DESC = "order-independent declarative definition of action-dependent controller methods - default rails CRUD actions"

Gem::Specification.new do |gem|
  gem.name          = "crud_methods"
  gem.version       = CrudMethods::VERSION
  gem.authors       = ["zelig"]
  gem.email         = ["viktor.tron@gmail.com"]
  gem.description   = DESC
  gem.summary       = DESC
  gem.homepage      = "https://github.com/zelig/crud_methods"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "state_methods"
  gem.add_dependency "rails"
  gem.add_development_dependency 'debugger'
  gem.add_development_dependency "rspec-rails"

end
