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

      def utime
        Time.at(self[:ru_utime][:tv_sec])
      end

      def stime
        Time.at(self[:ru_stime][:tv_sec])
      end

      def maxrss
        self[:ru_maxrss]
      end

      def ixrss
        self[:ru_ixrss]
      end

      def idrss
        self[:ru_idrss]
      end

      def isrss
        self[:ru_isrss]
      end

      def minflt
        self[:ru_minflt]
      end

      def majflt
        self[:ru_majflt]
      end

      def nswap
        self[:ru_nswap]
      end

      def inblock
        self[:ru_inblock]
      end

      def oublock
        self[:ru_oublock]
      end

      def msgsnd
        self[:ru_msgsnd]
      end

      def msgrcv
        self[:ru_msgrcv]
      end

      def nsignals
        self[:ru_nsignals]
      end

      def nvcsw
        self[:ru_nivcsw]
      end

      def nivcsw
        self[:ru_nivcsw]
      end
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
        :p_pid, :pid_t,
        :p_tid, :pid_t,
        :p_flags, :int,
        :p_stat, :lwpstat,
        :p_lock, :int,
        :p_tdflags, :int,
        :p_mpcount, :int,
        :p_prio, :int,
        :p_tdprio, :int,
        :p_rtprio, RTPrio,
        :p_uticks, :uint64_t,
        :p_sticks, :uint64_t,
        :p_iticks, :uint64_t,
        :p_cpticks, :uint64_t,
        :p_pctcpu, :uint,
        :p_slptime, :uint,
        :p_origcpu, :int,
        :p_estcpu, :int,
        :p_cpuid, :int,
        :p_ru, Rusage,
        :p_siglist, Sigset,
        :p_sigmask, Sigset,
        :p_wchan, :uint64_t,
        :p_wmesg, [:char, WMESGLEN+1],
        :p_comm, [:char, MAXCOMLEN+1]
      )

      def pid
        self[:p_pid]
      end

      def tid
        self[:p_tid]
      end

      def flags
        self[:p_flags]
      end

      def stat
        self[:p_stat]
      end

      def lock
        self[:p_lock]
      end

      def tdflags
        self[:p_tdflags]
      end

      def prio
        self[:p_prio]
      end

      def tdprio
        self[:p_tdprio]
      end

      def rtprio
        self[:p_rtprio]
      end

      def uticks
        self[:p_uticks]
      end

      def sticks
        self[:p_sticks]
      end

      def iticks
        self[:p_iticks]
      end

      def cpticks
        self[:p_cpticks]
      end

      def pctcpu
        self[:p_pctcpu]
      end

      def slptime
        self[:p_slptime]
      end

      def origcpu
        self[:p_origcpu]
      end

      def estcpu
        self[:p_estcpu]
      end

      def cpuid
        self[:p_cpuid]
      end

      def ru
        self[:p_ru]
      end

      def siglist
        self[:p_siglist]
      end

      def sigmask
        self[:p_sigmask]
      end

      def wchan
        self[:p_wchan]
      end

      def wmesg
        self[:p_wmesg].to_s
      end

      def comm
        self[:p_comm].to_s
      end
    end

    class KInfoProc < FFI::Struct
      include Sys::ProcTableConstants

      def self.roundup(x, y)
        ((x + y-1) / y) * y
      end

      layout(
        :p_paddr, :uint64_t,
        :p_flags, :int,
        :p_stat, :procstat,
        :p_lock, :int,
        :p_acflag, :int,
        :p_traceflag, :int,
        :p_fd, :uint64_t,
        :p_siglist, Sigset,
        :p_sigignore, Sigset,
        :p_sigcatch, Sigset,
        :p_sigflag, :int,
        :p_start, Timeval,
        :p_comm, [:char, MAXCOMLEN+1],
        :p_uid, :uid_t,
        :p_ngroups, :short,
        :p_groups, [:gid_t, NGROUPS],
        :p_ruid, :uid_t,
        :p_svuid, :uid_t,
        :p_rgid, :gid_t,
        :p_svgid, :gid_t,
        :p_pid, :pid_t,
        :p_ppid, :pid_t,
        :p_pgid, :pid_t,
        :p_jobc, :int,
        :p_sid, :pid_t,
        :p_login, [:char, roundup(MAXLOGNAME, FFI::Type::LONG.size)],
        :p_tdev, :dev_t,
        :p_tpgid, :pid_t,
        :p_tsid, :pid_t,
        :p_exitstat, :ushort,
        :p_nthreads, :int,
        :p_nice, :int,
        :p_swtime, :uint,
        :p_vm_map_size, :size_t,
        :p_vm_rssize, :segsz_t,
        :p_vm_swrss, :segsz_t,
        :p_vm_tsize, :segsz_t,
        :p_vm_dsize, :segsz_t,
        :p_vm_ssize, :segsz_t,
        :p_vm_prssize, :uint,
        :p_jailid, :int,
        :p_ru, Rusage,
        :p_cru, Rusage,
        :p_auxflags, :int,
        :p_lwp, KInfoLWP,
        :p_ktaddr, :uint64_t,
        :p_spare, [:int, 2]
      )
    end
  end
end
