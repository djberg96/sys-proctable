require 'ffi'

module Sys
  class ProcTable
    extend FFI::Library
    ffi_lib 'proc'

    private

    PROC_ALL_PIDS       = 1
    PROC_PIDTASKALLINFO = 2
    PROC_PIDTASKINFO    = 4

    MAXCOMLEN = 16
    MAXPATHLEN = 256
    PROC_PIDPATHINFO_MAXSIZE = MAXPATHLEN * 4

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
        :rfu1, :uint32_t,
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
    attach_function :proc_pidinfo, [:int, :int, :uint64_t, :pointer, :int], :int
    attach_function :proc_pidpath, [:int, :pointer, :uint32_t], :int

    @fields = %w[
      flags status xstatus pid ppid uid gid ruid rgid svuid svgid rfu1 comm
      name nfiles pgid pjobc tdev tpgid nice start_tvsec start_tvusec
      virtual_size resident_size total_user total_system threads_user
      threads_system policy faults pageins cow_faults messages_sent
      messages_received syscalls_mach syscalls_unix csw threadnum numrunning
      priority path
    ]

    # Add a couple aliases to make it similar to Linux
    ProcTableStruct = Struct.new("ProcTableStruct", *@fields) do
      alias vsize virtual_size
      alias rss resident_size
    end

    public

    def self.fields
      @fields
    end

    def self.ps(pid = nil)
      num = proc_listallpids(nil, 0)
      ptr = FFI::MemoryPointer.new(:pid_t, num)
      num = proc_listallpids(ptr, ptr.size)

      raise SystemCallError.new('proc_listallpids', FFI.errno) if num == 0

      pids  = ptr.get_array_of_int32(0, num).sort
      array = block_given? ? nil : []


      pids.each do |lpid|
        next unless pid == lpid if pid
        info = ProcTaskAllInfo.new

        if proc_pidinfo(lpid, PROC_PIDTASKALLINFO, 0, info, info.size) <= 0
          if [Errno::EPERM::Errno, Errno::ESRCH::Errno].include?(FFI.errno)
            next # Either we don't have permission, or the pid no longer exists
          else
            raise SystemCallError.new('proc_pidinfo', FFI.errno)
          end
        end

        struct = ProcTableStruct.new

        path = FFI::MemoryPointer.new(:char, PROC_PIDPATHINFO_MAXSIZE)

        if proc_pidpath(pid, path, path.size) > 0
          struct[:path] = path.read_string
        end

        info.members.each do |nested|
          info[nested].members.each do |member|
            temp = member.to_s.split('_')
            sproperty = temp.size > 1 ? temp[1..-1].join('_') : temp.first
            if info[nested][member].is_a?(FFI::StructLayout::CharArray)
              struct[sproperty.to_sym] = info[nested][member].to_s
            else
              struct[sproperty.to_sym] = info[nested][member]
            end
          end
        end

        if block_given?
          yield struct
        else
          array << struct
        end
      end

      pid ? array.first : array
    end
  end
end
