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

    private

    @fields = %w[
      pid ppid pgid tpgid sid tsid jobc uid ruid rgid
      ngroups groups size rssize swrss tsize dsize ssize
      xstat acflag pctcpu estcpu slptime swtime runtime start
      flag state nice lock rqindex oncpu lastcpu wmesg login
      lockname comm ttynum ttydev jid priority usrpri cmdline
      utime stime maxrss ixrss idrss isrss minflt majflt nswap
      inblock oublock msgsnd msgrcv nsignals nvcsw nivcsw
    ]

    ProcTableStruct = Struct.new('ProcTableStruct', *@fields)

    public

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
      errbuf = 0.chr * POSIX2_LINE_MAX

      begin
        kd = kvm_openfiles(nil, nil, nil, 0, errbuf)

        if kd.null?
          error = errbuf.split(0.chr).first
          raise SystemCallError.new("kvm_openfiles - #{error}", FFI.errno)
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
            kinfo[:ki_pid],
            kinfo[:ki_ppid],
            kinfo[:ki_pgid],
            kinfo[:ki_tpgid],
            kinfo[:ki_sid],
            kinfo[:ki_tsid],
            kinfo[:ki_jobc],
            kinfo[:ki_uid],
            kinfo[:ki_ruid],
            kinfo[:ki_rgid],
            kinfo[:ki_ngroups],
            kinfo[:ki_groups].to_a[0...kinfo[:ki_ngroups]],
            kinfo[:ki_size],
            kinfo[:ki_rssize],
            kinfo[:ki_swrss],
            kinfo[:ki_tsize],
            kinfo[:ki_dsize],
            kinfo[:ki_ssize],
            kinfo[:ki_xstat],
            kinfo[:ki_acflag],
            kinfo[:ki_pctcpu].to_f,
            kinfo[:ki_estcpu],
            kinfo[:ki_slptime],
            kinfo[:ki_swtime],
            kinfo[:ki_runtime],
            Time.at(kinfo[:ki_start][:tv_sec]),
            kinfo[:ki_flag],
            get_state(kinfo[:ki_stat]),
            kinfo[:ki_nice],
            kinfo[:ki_lock],
            kinfo[:ki_rqindex],
            kinfo[:ki_oncpu],
            kinfo[:ki_lastcpu],
            kinfo[:ki_wmesg].to_s,
            kinfo[:ki_login].to_s,
            kinfo[:ki_lockname].to_s,
            kinfo[:ki_comm].to_s,
            kinfo[:ki_tdev],
            devname(kinfo[:ki_tdev], S_IFCHR),
            kinfo[:ki_jid],
            kinfo[:ki_pri][:pri_level],
            kinfo[:ki_pri][:pri_user],
            cmd,
            kinfo[:ki_rusage][:ru_utime][:tv_sec],
            kinfo[:ki_rusage][:ru_stime][:tv_sec],
            kinfo[:ki_rusage][:ru_maxrss],
            kinfo[:ki_rusage][:ru_ixrss],
            kinfo[:ki_rusage][:ru_idrss],
            kinfo[:ki_rusage][:ru_isrss],
            kinfo[:ki_rusage][:ru_minflt],
            kinfo[:ki_rusage][:ru_majflt],
            kinfo[:ki_rusage][:ru_nswap],
            kinfo[:ki_rusage][:ru_inblock],
            kinfo[:ki_rusage][:ru_oublock],
            kinfo[:ki_rusage][:ru_msgsnd],
            kinfo[:ki_rusage][:ru_msgrcv],
            kinfo[:ki_rusage][:ru_nsignals],
            kinfo[:ki_rusage][:ru_nvcsw],
            kinfo[:ki_rusage][:ru_nivcsw]
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

    private_class_method :get_state
  end
end
