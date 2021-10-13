require 'rspec'
require 'rbconfig'

RSpec.configure do |config|
  if RbConfig::CONFIG['host_os'] =~ /darwin/ && RbConfig::CONFIG['host_os'].split(/\D+/).last.to_i >= 19
    config.filter_run_excluding(:skip_catalina_or_later)
  end
end
