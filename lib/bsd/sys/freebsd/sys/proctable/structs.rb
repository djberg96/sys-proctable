require 'ffi'
require_relative 'constants'

module Sys
  module ProcTableStructs
    extend FFI::Library

    class Timeval < FFI::Struct
      layout(:tv_sec, :time_t, :tv_usec, :suseconds_t)
    end

    class Priority < FFI::Struct
      layout(
        :pri_class, :uchar,
        :pri_level, :uchar,
        :pri_native, :uchar,
        :pri_user, :uchar
      )
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

    class Pargs < FFI::Struct
      layout(
        :ar_ref, :uint,
        :ar_length, :uint,
        :ar_args, [:uchar, 1]
      )
    end

    class KInfoProc < FFI::Struct
      layout(
        :ki_structsize, :int,
        :ki_layout, :int,
        :ki_args, :pointer,
        :ki_paddr, :pointer,
        :ki_addr, :pointer,
        :ki_tracep, :pointer,
        :ki_textvp, :pointer,
        :ki_fd, :pointer,
        :ki_vmspace, :pointer,
        :ki_wchan, :pointer,
        :ki_pid, :pid_t,
        :ki_ppid, :pid_t,
        :ki_pgid, :pid_t,
        :ki_tpgid, :pid_t,
        :ki_sid, :pid_t,
        :ki_tsid, :pid_t,
        :ki_jobc, :short,
        :ki_spare_short1, :short,
        :ki_tdev, :dev_t,
        :ki_siglist, [:uint32_t, 4],
        :ki_sigmask, [:uint32_t, 4],
        :ki_sigignore, [:uint32_t, 4],
        :ki_sigcatch, [:uint32_t, 4],
        :ki_uid, :uid_t,
        :ki_ruid, :uid_t,
        :ki_svuid, :uid_t,
        :ki_rgid, :gid_t,
        :ki_svgid, :gid_t,
        :ki_ngroups, :short,
        :ki_spare_short2, :short,
        :ki_groups, [:gid_t, KI_NGROUPS],
        :ki_size, :uint32_t,
        :ki_rssize, :segsz_t,
        :ki_swrss, :segsz_t,
        :ki_tsize, :segsz_t,
        :ki_dsize, :segsz_t,
        :ki_ssize, :segsz_t,
        :ki_xstat, :u_short,
        :ki_acflag, :u_short,
        :ki_pctcpu, :fixpt_t,
        :ki_estcpu, :uint,
        :ki_slptime, :uint,
        :ki_swtime, :uint,
        :ki_swtime, :int,
        :ki_runtime, :uint64_t,
        :ki_start, Timeval,
        :ki_childtime, Timeval,
        :ki_flag, :long,
        :ki_kiflag, :long,
        :ki_traceflag, :int,
        :ki_stat, :char,
        :ki_nice, :char,
        :ki_lock, :char,
        :ki_rqindex, :char,
        :ki_oncpu, :uchar,
        :ki_lastcpu, :uchar,
        :ki_ocomm, [:char, OCOMMLEN+1],
        :ki_wmesg, [:char, WMESGLEN+1],
        :ki_login, [:char, LOGNAMELEN+1],
        :ki_lockname, [:char, LOCKNAMELEN+1],
        :ki_comm, [:char, COMMLEN+1],
        :ki_emul, [:char, KI_EMULNAMELEN+1],
        :ki_sparestrings, [:char, 68],
        :ki_spareints, [:int, KI_NSPARE_INT],
        :ki_cr_flags, :uint,
        :ki_jid, :int,
        :ki_numthreads, :int,
        :ki_tid, :pid_t,
        :ki_pri, Priority,
        :ki_rusage, Rusage,
        :ki_rusage_ch, Rusage,
        :ki_pcb, :pointer,
        :ki_kstack, :pointer,
        :ki_udata, :pointer,
        :ki_tdaddr, :pointer,
        :ki_spareptrs, [:pointer, KI_NSPARE_PTR],
        :ki_sparelongs, [:long, KI_NSPARE_LONG],
        :ki_sflags, :long,
        :ki_tdflags, :long
      )
    end
  end
end
