# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'bundler/version'
 
Gem::Specification.new do |s|
  s.name        = "fake_arel"
  s.version     = "0.9.9"
  s.platform    = Gem::Platform::RUBY
  s.author     = "Grant Ammons"
  s.email       = ["grant@pipelinedealsco.com"]
  s.homepage    = "http://github.com/gammons/fake_arel"
  s.summary     = "A library that simulates Rails 3 ActiveRecord Arel calls using extensions to named_scope."
 
  s.add_dependency('activerecord', '~>2.3.5')
  s.rubyforge_project = 'fake_arel'
 
  s.files        = Dir.glob("{bin,lib}/**/*")
  s.require_path = 'lib'
end
