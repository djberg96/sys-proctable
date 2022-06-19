case RbConfig::CONFIG['host_os']
  when /freebsd/i
    require_relative 'freebsd/sys/proctable'
  when /dragonfly/i
    require_relative 'dragonfly/sys/proctable'
  else
    raise "Unsupported version of BSD"
end
