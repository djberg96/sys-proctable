require 'rspec'
require 'rbconfig'

RSpec.configure do |config|
  if RbConfig::CONFIG['host_os'] =~ /darwin/ && RbConfig::CONFIG['host_os'].split(/\D+/).last.to_i >= 20
    config.filter_run_excluding(:skip_big_sur)
  end
end
