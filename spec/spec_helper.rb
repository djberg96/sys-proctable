require 'rspec'
require 'sys-proctable'
require 'sys-top'
require 'sys_proctable_common'

RSpec.configure do |config|
  config.include_context('common')
  config.filter_run_excluding(:jruby) if RUBY_PLATFORM == 'java'
end
