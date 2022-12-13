require 'rspec'
require 'sys-proctable'
require 'sys-top'

RSpec.configure do |config|
  config.filter_run_excluding(:aix) unless RbConfig::CONFIG['host_os'] =~ /aix/i
  config.filter_run_excluding(:darwin) unless RbConfig::CONFIG['host_os'] =~ /mac|darwin/i
  config.filter_run_excluding(:linux) unless RbConfig::CONFIG['host_os'] =~ /linux/i
  config.filter_run_excluding(:bsd) unless RbConfig::CONFIG['host_os'] =~ /bsd|dragonfly/i
  config.filter_run_excluding(:freebsd) unless RbConfig::CONFIG['host_os'] =~ /freebsd/i
  config.filter_run_excluding(:dragonfly) unless RbConfig::CONFIG['host_os'] =~ /dragonfly/i
  config.filter_run_excluding(:sunos) unless RbConfig::CONFIG['host_os'] =~ /sunos|solaris/i
  config.filter_run_excluding(:windows) unless Gem.win_platform?
  config.filter_run_excluding(:jruby) if RUBY_PLATFORM == 'java'
end
