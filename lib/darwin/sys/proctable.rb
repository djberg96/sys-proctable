require 'ffi'

module Sys
  class ProcTable
    extend FFI::Library
    ffi_lib FFI::Library::LIBC

    private

    MAXCOMLEN = 16
    MAXLOGNAME = 17
    NGROUPS = 16

    attach_function :sysctl, [:pointer, :uint, :pointer, :pointer, :pointer, :size_t], :int
    attach_function :strerror, [:int], :string

    typedef :int32_t, :dev_t
    typedef :int32_t, :segsz_t
    typedef :int32_t, :swblk_t
    typedef :uint32_t, :sigset_t
    typedef :int, :pid_t
    typedef :pointer, :caddr_t # char*
    typedef :uint, :boolean_t
    typedef :uint, :lck_mtx_t

    private_class_method :sysctl

    CTL_KERN      = 1
    KERN_PROC     = 14
    KERN_PROC_ALL = 0

    # sizeof(struct kinfo_proc) == 648

    # Process info appears to be stored in a rat hole of nested
    # structs on OSX. :(

    class UnUnion < FFI::Union
      layout(
        :p_st1, :pointer,
        :p_starttime, :pointer
      )
    end

    # /usr/include/sys/vm.h
    class VmSpaceStruct < FFI::Struct
      layout(
        :dummy, :int32_t,
        :dummy2, :caddr_t,
        :dummy3, [:int32_t, 5],
        :dummy4, [:caddr_t, 3]
      )
    end

    # Aka extern_proc (sys/proc.h)
    class KpProcStruct < FFI::Struct
      layout(
        :p_un, UnUnion,
        :p_vmspace, VmSpaceStruct,
        :p_sigacts, :pointer,
        :p_flag, :int,
        :p_pid, :pid_t,
        :p_oppid, :pid_t,
        :p_dupfd, :int,
        :user_stack, :caddr_t,
        :exit_thread, :pointer,
        :p_debugger, :int,
        :sigwait, :boolean_t,
        :p_estcpu, :uint,
        :p_cpticks, :int,
        :p_pctcpu, :fixpt_t,
        :p_wchan, :pointer,
        :p_wmesg, :pointer,
        :p_swtime, :uint,
        :p_slptime, :uint,
        :p_realtimer, :pointer,
        :p_rtime, :pointer,
        :p_uticks, :u_quad_t,
        :p_sticks, :u_quad_t,
        :p_iticks, :u_quad_t,
        :p_traceflag, :int,
        :p_tracerep, :pointer,
        :p_siglist, :int,
        :p_textvp, :pointer,
        :p_holdcnt, :int,
        :p_sigmask, :sigset_t,
        :p_sigignore, :sigset_t,
        :p_sigcatch, :sigset_t,
        :p_priority, :uchar,
        :p_usrpri, :uchar,
        :p_nic, :char,
        :p_comm, [:char, MAXCOMLEN+1],
        :p_pgrp, :pointer,
        :p_addr, :pointer,
        :p_xstat, :ushort,
        :p_acflag, :ushort,
        :p_ru, :pointer
      )
    end

    # check_sizeof('struct extern_proc', 'sys/sysctl.h') # => 296

    p KpProcStruct.size

    # Can't find this on OSX, this is a guess based on the intertubes.
    class SessionStruct < FFI::Struct
      layout(
        :s_count, :int,
        :s_leader, :pointer,
        :s_ttyvp, :pointer,
        :s_ttyvid, :int,
        :s_ttyp, :pointer,
        :s_ttypgrpid, :pid_t,
        :s_sid, :pid_t,
        :s_login, [:char, MAXLOGNAME],
        :s_flags, :int,
        :s_hash, :pointer,
        :s_mlock, :lck_mtx_t,
        :s_listflags, :int
      )
    end

    class PCredStruct < FFI::Struct
      layout(
        :pc_lock, [:char, 72],
        :pc_ucred, :pointer,
        :p_ruid, :uid_t,
        :p_svuid, :uid_t,
        :p_rgid, :gid_t,
        :p_svgid, :gid_t,
        :p_refcnt, :int
      )
    end

    # check_sizeof('struct _pcred', 'sys/sysctl.h') # => 104

    class UCredStruct < FFI::Struct
      layout(
        :cr_ref, :int32_t,
        :cr_uid, :uid_t,
        :cr_ngroups, :short,
        :cr_groups, [:gid_t, NGROUPS]
      )
    end

    # check_sizeof('struct _ucred', 'sys/sysctl.h') # => 76

    class EProcStruct < FFI::Struct
      layout(
        :e_paddr, :pointer,
        :e_sess, SessionStruct,
        :e_pcred, PCredStruct,
        :e_ucred, UCredStruct,
        :e_vm, :pointer,
        :e_ppid, :pid_t,
        :e_pgid, :pid_t,
        :e_jobc, :short,
        :e_tdev, :dev_t,
        :e_tpgid, :pid_t,
        :e_tsess, :pointer,
        :e_wmesg, [:char, 8],
        :e_xsize, :segsz_t,
        :e_xrssize, :short,
        :e_xccount, :short,
        :e_xswrss, :short,
        :e_flag, :int32_t,
        :e_login, [:char, 12],
        :e_spare, [:int32_t, 4]
      )
    end

    #p EProcStruct.size

    # check_sizeof('struct eproc', 'sys/sysctl.h') # => 352

    class KInfoProcStruct < FFI::Struct
      layout(
        :kp_proc, KpProcStruct,
        :eproc, EProcStruct
      )
    end

    #p KInfoProcStruct.size

    # check_sizeof('struct kinfo_proc', 'sys/sysctl.h') # => 648

    public

    def self.ps(pid = nil)
      len = FFI::MemoryPointer.new(:size_t)
      mib = FFI::MemoryPointer.new(:int, 4)

      mib.write_array_of_int([CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0])

      # First pass, determine length
      if sysctl(mib, 4, nil, len, nil, 0) < 0
        raise Error, "sysctl function failed: " + strerror(FFI.errno)
      end

      procs = FFI::MemoryPointer.new(:pointer, len.read_long)
      len   = FFI::MemoryPointer.new(:size_t)

      if sysctl(mib, 4, procs, len, nil, 0) < 0
        raise Error, "sysctl function failed: " + strerror(FFI.errno)
      end

      # count = len.read_long / KInfoProcStruct.size
    end
  end
end

if $0 == __FILE__
  include Sys
  ProcTable.ps(Process.pid)
end
