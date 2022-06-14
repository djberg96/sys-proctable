require 'rspec'
require 'sys-proctable'
require 'sys-top'

RSpec.configure do |config|
  config.filter_run_excluding(:jruby) if RUBY_PLATFORM == 'java'
end
