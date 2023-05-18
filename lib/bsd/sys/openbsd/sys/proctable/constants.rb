require 'ffi'
require 'ffi/tools/const_generator'
module Sys
  module ProcTableConstants
    WMESGLEN   = 8
    MAXCOMLEN  = 16
    NGROUPS    = 16
    MAXLOGNAME = 33

    KERN_PROC_ALL  = 0
    KERN_PROC_PID = 1

    ESIZE = 4
    FFI_CG = FFI::ConstGenerator.new('kvm', required: true) do |gen|
      gen.const(:KVM_NO_FILES)
    end
  end
end
