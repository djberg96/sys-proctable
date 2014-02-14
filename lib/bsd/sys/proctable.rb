require 'ffi'

module Sys
  class ProcTable
    extend FFI::Library

    private

    ffi_lib :kvm

    attach_function :devname, [:dev_t, :mode_t], :string
    attach_function :kvm_open, [:string, :string, :string, :int, :string], :pointer
    attach_function :kvm_close, [:pointer], :int
    attach_function :kvm_getprocs, [:pointer, :int, :int, :pointer], :pointer
    attach_function :kvm_getargv, [:pointer, :pointer, :int], :pointer

    KERN_PROC_ALL  = 0
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
        :ar_args, [:uchar,1]
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
        :ki_size, :vm_size_t,
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
        :ki_tid, :lwpid_t,
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

    ProcTableStruct = Struct.new('ProcTableStruct',
      :pid, :ppid, :pgid, :ruid, :rgid, :comm, :state, :pctcpu, :oncpu,
      :ttynum, :ttydev, :wmesg, :time, :priority, :usrpri, :nice, :cmdline,
      :start, :maxrss, :ixrss, :idrss, :isrss, :minflt, :majflt, :nswap,
      :inblock, :oublock, :msgsnd, :msgrcv, :nsignals, :nvcsw, :nivcsw,
      :utime, :stime
    )

    public

    def self.ps(pid = nil)
      begin
        kd = kvm_open(nil, nil, nil, 0, 'kvm_open')

        if kd.null?
          raise SystemCallError.new('kvm_open', FFI.errno)
        end

        ptr = FFI::MemoryPointer.new(:int)

        if pid
          procs = kvm_getprocs(kd, KERN_PROC_PID, pid, ptr)
        else
          procs = kvm_getprocs(kd, KERN_PROC_PROC, 0, ptr)
        end

        if procs.null?
          raise SystemCallError.new('kvm_getprocs', FFI.errno)
        end

        cmd = nil

        if pid
          kinfo = KInfoProc.new(procs)

          args = kvm_getargv(kd, kinfo, 0)

          if args
            cmd = ''
            ptr = args.read_pointer

            while str = ptr.read_string
              break if str.empty?
              cmd << str + ' '
              ptr += str.size + 1
            end
          end

          ProcTableStruct.new(
            kinfo[:ki_pid],
            kinfo[:ki_ppid],
            kinfo[:ki_pgid],
            kinfo[:ki_ruid],
            kinfo[:ki_rgid],
            kinfo[:ki_comm].to_s,
            get_state(kinfo[:ki_stat]),
            kinfo[:ki_pctcpu].to_f,
            kinfo[:ki_oncpu],
            kinfo[:ki_tdev],
            devname(kinfo[:ki_tdev], S_IFCHR),
            kinfo[:ki_wmesg].to_s,
            kinfo[:ki_runtime]/1000000,
            kinfo[:ki_pri][:pri_level],
            kinfo[:ki_pri][:pri_user],
            kinfo[:ki_nice],
            cmd.strip,
            Time.at(kinfo[:ki_start][:tv_sec]),
          )
        else
          count = ptr.read_int
          array = []

          0.upto(count - 1){ |i|
            kinfo = KInfoProc.new(procs[i * KInfoProc.size])

            s = ProcTableStruct.new(
              kinfo[:ki_pid],
              kinfo[:ki_ppid]
            )
          }
        end
      ensure
        kvm_close(kd) unless kd.null?
      end
    end

    private

    SIDL   = 1
    SRUN   = 2
    SSLEEP = 3
    SSTOP  = 4
    SZOMB  = 5
    SWAIT  = 6
    SLOCK  = 7

    def self.get_state(int)
      case int
        when SIDL; "idle"
        when SRUN; "run"
        when SSLEEP; "sleep"
        when SSTOP; "stop"
        when SZOMB; "zombie"
        when SWAIT; "waiting"
        when SLOCK; "locked"
        else; "unknown"
      end
    end
  end
end

if $0 == __FILE__
  include Sys
  p ProcTable.ps(2456)
  #ProcTable.ps
end
