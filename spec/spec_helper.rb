require 'rubygems'
gem 'rspec'
gem 'activerecord'

$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__) + '/fixtures')
$:.unshift(File.dirname(__FILE__) + '/models')

require 'active_record'
require 'active_record/fixtures'
require 'fake_arel'
gem 'sqlite3-ruby'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => 'spec/test.db')
ActiveRecord::Base.logger = Logger.new(STDOUT) if $0 == 'irb'

ActiveRecord::Base.silence do
  ActiveRecord::Migration.verbose = false

  # load schema
  load File.join('spec/fixtures/schema.rb')
  # load fixtures
  Fixtures.create_fixtures("spec/fixtures", ActiveRecord::Base.connection.tables)
end
