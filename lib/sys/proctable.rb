require 'rbconfig'

case RbConfig::CONFIG['host_os']
  when /aix/i
    require_relative '../aix/sys/proctable'
  when /darwin/i
    require_relative '../darwin/sys/proctable'
  when /freebsd|dragonfly/i
    require_relative '../bsd/sys/proctable'
  when /linux/i
    require_relative '../linux/sys/proctable'
  when /mswin|win32|dos|cygwin|mingw|windows/i
    require_relative '../windows/sys/proctable'
  else
    raise "Unsupported platform"
end
