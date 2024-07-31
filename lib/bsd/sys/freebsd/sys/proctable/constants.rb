module Sys
  module ProcTableConstants
    POSIX_ARG_MAX = 4096

    KERN_PROC_PID  = 1
    KERN_PROC_PROC = 8

    S_IFCHR = 0020000

    WMESGLEN       = 8
    LOCKNAMELEN    = 8
    OCOMMLEN       = 16
    COMMLEN        = 19
    KI_EMULNAMELEN = 16
    KI_NGROUPS     = 16
    LOGNAMELEN     = 17
    KI_NSPARE_INT  = 9
    KI_NSPARE_LONG = 12
    KI_NSPARE_PTR  = 6

    SIDL   = 1
    SRUN   = 2
    SSLEEP = 3
    SSTOP  = 4
    SZOMB  = 5
    SWAIT  = 6
    SLOCK  = 7
  end
end
