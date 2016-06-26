require 'ffi'

module Sys
  class ProcTable
    extend FFI::Library
    ffi_lib 'proc'

    PROC_ALL_PIDS       = 1
    PROC_PIDTASKALLINFO = 2
    PROC_PIDTASKINFO    = 4

    MAXCOMLEN = 16

    class ProcBsdInfo < FFI::Struct
      layout(
        :pbi_flags, :uint32_t,
        :pbi_status, :uint32_t,
        :pbi_xstatus, :uint32_t,
        :pbi_pid, :uint32_t,
        :pbi_ppid, :uint32_t,
        :pbi_uid, :uid_t,
        :pbi_gid, :uid_t,
        :pbi_ruid, :uid_t,
        :pbi_rgid, :gid_t,
        :pbi_svuid, :uid_t,
        :pbi_svgid, :gid_t,
        :rfu_1, :uint32_t,
        :pbi_comm, [:char, MAXCOMLEN],
        :pbi_name, [:char, MAXCOMLEN * 2],
        :pbi_nfiles, :uint32_t,
        :pbi_pgid, :uint32_t,
        :pbi_pjobc, :uint32_t,
        :e_tdev, :uint32_t,
        :e_tpgid, :uint32_t,
        :pbi_nice, :int32_t,
        :pbi_start_tvsec, :uint64_t,
        :pbi_start_tvusec, :uint64_t
      )
    end

    class ProcTaskInfo < FFI::Struct
      layout(
        :pti_virtual_size, :uint64_t,
        :pti_resident_size, :uint64_t,
        :pti_total_user, :uint64_t,
        :pti_total_system, :uint64_t,
        :pti_threads_user, :uint64_t,
        :pti_threads_system, :uint64_t,
        :pti_policy, :int32_t,
        :pti_faults, :int32_t,
        :pti_pageins, :int32_t,
        :pti_cow_faults, :int32_t,
        :pti_messages_sent, :int32_t,
        :pti_messages_received, :int32_t,
        :pti_syscalls_mach, :int32_t,
        :pti_syscalls_unix, :int32_t,
        :pti_csw, :int32_t,
        :pti_threadnum, :int32_t,
        :pti_numrunning, :int32_t,
        :pti_priority, :int32_t
      )
    end

    class ProcTaskAllInfo < FFI::Struct
      layout(:pbsd, ProcBsdInfo, :ptinfo, ProcTaskInfo)
    end

    attach_function :proc_listpids, [:uint32_t, :uint32_t, :pointer, :int], :int
    attach_function :proc_listallpids, [:pointer, :int], :int

    def self.ps(pid = nil)
      size = proc_listpids(PROC_PIDTASKALLINFO, 0, nil, 0)
      ptr  = FFI::MemoryPointer.new(ProcTaskAllInfo, size)

      if proc_listpids(PROC_PIDTASKALLINFO, 0, ptr, ptr.size) == 0
        raise SystemCallError.new('proc_listpids', FFI.errno)
      end

      count = proc_listallpids(ptr, ptr.size)

      raise SystemCallError.new('proc_listallpids', FFI.errno) if count == 0

      # TODO: Fix
      0.upto(count) do |index|
        struct = ProcTaskAllInfo.new(ptr + (index * ProcTaskAllInfo.size))
        p struct[:pbsd][:pbi_pid]
        p struct[:pbsd][:pbi_comm].to_s
      end
    end
  end
end

Sys::ProcTable.ps
