module Sys
  module ProcTableConstants
    WMESGLEN   = 8
    MAXCOMLEN  = 16
    NGROUPS    = 16
    MAXLOGNAME = 33

    KERN_PROC_ALL  = 0
    KERN_PROC_PID = 1

    ESIZE = 4
    # KVM_NO_FILES = 0x80000000 # To big for int type but defined in kvm.h
    KVM_NO_FILES = 0
  end
end
