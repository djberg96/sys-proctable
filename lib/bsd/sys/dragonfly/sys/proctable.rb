require_relative 'proctable/constants'
require_relative 'proctable/structs'
require_relative 'proctable/functions'

module Sys
  class ProcTable
    include Sys::ProcTableConstants
    include Sys::ProcTableStructs
    extend Sys::ProcTableFunctions

    # Error typically raised if the ProcTable.ps method fails.
    class Error < StandardError; end

    # There is no constructor
    private_class_method :new

=begin
      pid tid flags stat lock tdflags mpcount prio tdprio rtprio
      uticks sticks iticks cpticks pctcpu slptime origcpu estcpu
      cpuid ru siglist sigmask wchan wmesg comm
=end

    @fields = %w[
      paddr flags stat lock acflag traceflag fd siglist sigignore
      sigcatch sigflag start comm uid ngroups groups ruid svuid
      rgid svgid pid ppid pgid jobc sid login tdev tpgid tsid exitstat
      nthreads nice swtime vm_map_size vm_rssize vm_swrss vm_tsize
      vm_dsize vm_ssize vm_prssize jailid ru cru auxflags lwp ktaddr
    ]

    ProcTableStruct = Struct.new('ProcTableStruct', *@fields)

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
    #   p ProcTable.ps(1001)
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
          procs = kvm_getprocs(kd, KERN_PROC_PROC, 0, ptr)
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
            kinfo[:kp_paddr]
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
  end
end

p Sys::ProcTable.ps(:pid => Process.pid)
