$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'active_record' unless defined?(ActiveRecord)
require 'fake_arel/singleton_class'
require 'fake_arel/extensions'
require 'fake_arel/with_scope_replacement'
require 'fake_arel/rails_3_finders'

module FakeArel
  VERSION = '0.0.1'
  ActiveRecord::Base.send :include, Rails3Finders
  ActiveRecord::Base.send :include, WithScopeReplacement
end
