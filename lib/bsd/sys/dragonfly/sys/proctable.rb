require_relative 'proctable/constants'
require_relative 'proctable/structs'
require_relative 'proctable/functions'
require 'sys/proctable/version'

module Sys
  class ProcTable
    include Sys::ProcTableConstants
    include Sys::ProcTableStructs
    extend Sys::ProcTableFunctions

    # Error typically raised if the ProcTable.ps method fails.
    class Error < StandardError; end

    # There is no constructor
    private_class_method :new

    @fields = %w[
      paddr flags stat lock acflag traceflag fd siglist sigignore
      sigcatch sigflag start comm uid ngroups groups ruid svuid
      rgid svgid pid ppid pgid jobc sid login tdev tpgid tsid exitstat
      nthreads nice swtime vm_map_size vm_rssize vm_swrss vm_tsize
      vm_dsize vm_ssize vm_prssize jailid ru cru auxflags lwp ktaddr
    ]

    ProcTableStruct = Struct.new('ProcTableStruct', *@fields) do
      alias cmdline comm
    end

    # In block form, yields a ProcTableStruct for each process entry that you
    # have rights to. This method returns an array of ProcTableStruct's in
    # non-block form.
    #
    # If a +pid+ is provided, then only a single ProcTableStruct is yielded or
    # returned, or nil if no process information is found for that +pid+.
    #
    # Example:
    #
    #   # Iterate over all processes
    #   ProcTable.ps do |proc_info|
    #      p proc_info
    #   end
    #
    #   # Print process table information for only pid 1001
    #   p ProcTable.ps(pid: 1001)
    #
    def self.ps(**kwargs)
      pid = kwargs[:pid]

      begin
        kd = kvm_open(nil, nil, nil, 0, nil)

        if kd.null?
          raise SystemCallError.new('kvm_open', FFI.errno)
        end

        ptr = FFI::MemoryPointer.new(:int) # count

        if pid
          procs = kvm_getprocs(kd, KERN_PROC_PID, pid, ptr)
        else
          procs = kvm_getprocs(kd, KERN_PROC_ALL, 0, ptr)
        end

        if procs.null?
          if pid && FFI.errno == Errno::ESRCH::Errno
            return nil
          else
            raise SystemCallError.new('kvm_getprocs', FFI.errno)
          end
        end

        count = ptr.read_int
        array = []

        0.upto(count-1){ |i|
          cmd = nil
          kinfo = KInfoProc.new(procs[i * KInfoProc.size])

          args = kvm_getargv(kd, kinfo, 0)

          unless args.null?
            cmd = []

            until ((ptr = args.read_pointer).null?)
              cmd << ptr.read_string
              args += FFI::Type::POINTER.size
            end

            cmd = cmd.join(' ')
          end

          struct = ProcTableStruct.new(
            kinfo[:kp_paddr],
            kinfo[:kp_flags],
            kinfo[:kp_stat],
            kinfo[:kp_lock],
            kinfo[:kp_acflag],
            kinfo[:kp_traceflag],
            kinfo[:kp_fd],
            kinfo[:kp_siglist].bits,
            kinfo[:kp_sigignore].bits,
            kinfo[:kp_sigcatch].bits,
            kinfo[:kp_sigflag],
            Time.at(kinfo[:kp_start][:tv_sec]),
            kinfo[:kp_comm].to_s,
            kinfo[:kp_uid],
            kinfo[:kp_ngroups],
            kinfo[:kp_groups].to_a[0..kinfo[:kp_ngroups]-1],
            kinfo[:kp_ruid],
            kinfo[:kp_svuid],
            kinfo[:kp_rgid],
            kinfo[:kp_svgid],
            kinfo[:kp_pid],
            kinfo[:kp_ppid],
            kinfo[:kp_pgid],
            kinfo[:kp_jobc],
            kinfo[:kp_sid],
            kinfo[:kp_login].to_s,
            kinfo[:kp_tdev],
            kinfo[:kp_tpgid],
            kinfo[:kp_tsid],
            kinfo[:kp_exitstat],
            kinfo[:kp_nthreads],
            kinfo[:kp_nice],
            kinfo[:kp_swtime],
            kinfo[:kp_vm_map_size],
            kinfo[:kp_vm_rssize],
            kinfo[:kp_vm_swrss],
            kinfo[:kp_vm_tsize],
            kinfo[:kp_vm_dsize],
            kinfo[:kp_vm_ssize],
            kinfo[:kp_vm_prssize],
            kinfo[:kp_jailid],
            kinfo[:kp_ru],
            kinfo[:kp_cru],
            kinfo[:kp_auxflags],
            kinfo[:kp_lwp],
            kinfo[:kp_ktaddr],
          )

          struct.freeze # This is readonly data

          if block_given?
            yield struct
          else
            array << struct
          end
        }
      ensure
        kvm_close(kd) unless kd.null?
      end

      if block_given?
        nil
      else
        pid ? array.first : array
      end
    end

    # Returns an array of fields that each ProcTableStruct will contain. This
    # may be useful if you want to know in advance what fields are available
    # without having to perform at least one read of the /proc table.
    #
    # Example:
    #
    #   Sys::ProcTable.fields.each{ |field|
    #      puts "Field: #{field}"
    #   }
    #
    def self.fields
      @fields
    end
  end
end
