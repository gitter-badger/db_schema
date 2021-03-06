$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'db_schema'
require 'pry'
require 'awesome_print'
AwesomePrint.pry!

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!

  config.profile_examples = 10

  config.before(:all) do
    DbSchema.configure(database: 'db_schema_test')
  end
end
