module Sys
  module ProcTableConstants
    POSIX_ARG_MAX = 4096
    POSIX2_LINE_MAX = 2048
    FSCALE = 1 << 11

    KERN_PROC_PID  = 1
    KERN_PROC_PROC = 8

    NODEV = -1
    NODEV_U64 = (1 << 64) - 1

    S_IFCHR = 0020000

    WMESGLEN       = 8
    LOCKNAMELEN    = 8
    OCOMMLEN       = 16
    TDNAMLEN       = 16
    COMMLEN        = 19
    MAXCOMLEN      = 19
    KI_EMULNAMELEN = 16
    KI_NGROUPS     = 16
    LOGNAMELEN     = 17
    LOGINCLASSLEN  = 17
    KI_NSPARE_INT  = 9
    KI_NSPARE_LONG = 12
    KI_NSPARE_PTR  = 6
    KI_NSPARE_INT_FREEBSD12 = 2
    KI_NSPARE_PTR_FREEBSD12 = 4

    SIDL   = 1
    SRUN   = 2
    SSLEEP = 3
    SSTOP  = 4
    SZOMB  = 5
    SWAIT  = 6
    SLOCK  = 7
  end
end
