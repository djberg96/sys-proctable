require 'ffi'

module Sys
  class ProcTable
    extend FFI::Library
    ffi_lib FFI::Library::LIBC

    attach_function(
      :sysctl,
      [:pointer, :uint, :pointer, :pointer, :pointer, :size_t],
      :int
    )

    attach_function(:strerror, [:int], :string)

    private_class_method :sysctl

    CTL_KERN      = 1
    KERN_PROC     = 14
    KERN_PROC_ALL = 0

    # sizeof(struct kinfo_proc) == 648

    # Process info appears to be stored in a rat hole of nested
    # structs on OSX. :(

    # extern_proc
    class KpProcStruct < FFI::Struct
      layout(
        :p_un, UnUnion,
        :p_vmspace, VmspaceStruct,

      )
    end

    class EProcStruct < FFI::Struct
      layout(
        :e_paddr, ProcStruct,
        :e_sess, SessionStruct,
        :e_pcred, PCredStruct,
        :e_ucred, UCredStruct,
        :e_vm, VMSpaceStruct,
        :e_ppid, :int,
        :e_pgid, :int,
        :e_jobc, :short,
        :e_tdev, :uint, # Not sure
        :e_tpgid, :int,
        :e_tsess, SessionStruct,
        :e_wmesg, [:char, 8],
        :e_xsize, :ulong, # Not sure
        :e_xrssize, :short,
        :e_flag, :int32,
        :e_login, [:char, 12],
        :e_spare, [:int32, 4]
      )
    end

    class KInfoStruct < FFI::Struct
      layout(
        :kp_proc, KpProcStruct,
        :eproc, EProcStruct
      )
    end

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

      # count = len.read_long / KInfoStruct.size
    end
  end
end

if $0 == __FILE__
  include Sys
  ProcTable.ps(Process.pid)
end
