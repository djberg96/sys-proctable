require 'ffi'
require_relative 'constants'

module Sys
  module ProcTableStructs
    extend FFI::Library

    class Timeval < FFI::Struct
      layout(:tv_sec, :time_t, :tv_usec, :suseconds_t)
    end

    class RTPrio < FFI::Struct
      layout(:type, :ushort, :prio, :ushort)
    end

    class Rusage < FFI::Struct
      layout(
        :ru_utime, Timeval,
        :ru_stime, Timeval,
        :ru_maxrss, :long,
        :ru_ixrss, :long,
        :ru_idrss, :long,
        :ru_isrss, :long,
        :ru_minflt, :long,
        :ru_majflt, :long,
        :ru_nswap, :long,
        :ru_inblock, :long,
        :ru_oublock, :long,
        :ru_msgsnd, :long,
        :ru_msgrcv, :long,
        :ru_nsignals, :long,
        :ru_nvcsw, :long,
        :ru_nivcsw, :long
      )
    end

    enum :lwpstat, [:LSRUN, 1, :LSSTOP, :LSSLEEP]
    enum :procstat, [:SIDL, 1, :SACTIVE, :SSTOP, :SZOMB, :SCORE]

    class Sigset < FFI::Struct
      layout(:__bits, [:uint, 4])

      def bits
        self[:__bits].to_a
      end
    end

    class KInfoLWP < FFI::Struct
      include Sys::ProcTableConstants

      layout(
        :kl_pid, :pid_t,
        :kl_tid, :lwpid_t,
        :kl_flags, :int,
        :kl_stat, :lwpstat,
        :kl_lock, :int,
        :kl_tdflags, :int,
        :kl_mpcount, :int,
        :kl_prio, :int,
        :kl_tdprio, :int,
        :kl_rtprio, RTPrio,
        :kl_uticks, :uint64_t,
        :kl_sticks, :uint64_t,
        :kl_iticks, :uint64_t,
        :kl_cpticks, :uint64_t,
        :kl_pctcpu, :uint,
        :kl_slptime, :uint,
        :kl_origcpu, :int,
        :kl_estcpu, :int,
        :kl_cpuid, :int,
        :kl_ru, Rusage,
        :kl_siglist, Sigset,
        :kl_sigmask, Sigset,
        :kl_wchan, :uintptr_t,
        :kl_wmesg, [:char, WMESGLEN+1],
        :kl_comm, [:char, MAXCOMLEN+1]
      )
    end

    class KInfoProc < FFI::Struct
      include Sys::ProcTableConstants

      def self.roundup(x, y)
        ((x + y-1) / y) * y
      end

      layout(
        :kp_paddr, :uintptr_t,
        :kp_flags, :int,
        :kp_stat, :procstat,
        :kp_lock, :int,
        :kp_acflag, :int,
        :kp_traceflag, :int,
        :kp_fd, :uintptr_t,
        :kp_siglist, Sigset,
        :kp_sigignore, Sigset,
        :kp_sigcatch, Sigset,
        :kp_sigflag, :int,
        :kp_start, Timeval,
        :kp_comm, [:char, MAXCOMLEN+1],
        :kp_uid, :uid_t,
        :kp_ngroups, :short,
        :kp_groups, [:gid_t, NGROUPS],
        :kp_ruid, :uid_t,
        :kp_svuid, :uid_t,
        :kp_rgid, :gid_t,
        :kp_svgid, :gid_t,
        :kp_pid, :pid_t,
        :kp_ppid, :pid_t,
        :kp_pgid, :pid_t,
        :kp_jobc, :int,
        :kp_sid, :pid_t,
        :kp_login, [:char, roundup(MAXLOGNAME, FFI::Type::LONG.size)],
        :kp_tdev, :dev_t,
        :kp_tpgid, :pid_t,
        :kp_tsid, :pid_t,
        :kp_exitstat, :ushort,
        :kp_nthreads, :int,
        :kp_nice, :int,
        :kp_swtime, :uint,
        :kp_vm_map_size, :size_t,
        :kp_vm_rssize, :segsz_t,
        :kp_vm_swrss, :segsz_t,
        :kp_vm_tsize, :segsz_t,
        :kp_vm_dsize, :segsz_t,
        :kp_vm_ssize, :segsz_t,
        :kp_vm_prssize, :uint,
        :kp_jailid, :int,
        :kp_ru, Rusage,
        :kp_cru, Rusage,
        :kp_auxflags, :int,
        :kp_lwp, KInfoLWP,
        :kp_ktaddr, :uintptr_t,
        :kp_spare, [:int, 2]
      )
    end
  end
end
