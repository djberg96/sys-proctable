require 'rspec'
require 'sys-proctable'

RSpec.configure do |config|
  config.filter_run_excluding(:jruby) if RUBY_PLATFORM == 'java'
end
