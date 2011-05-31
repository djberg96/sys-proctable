########################################################################
# proctable.rb
#
# A pure Ruby version of sys-proctable for SunOS 5.8 or later.
########################################################################

# The Sys module serves as a namespace only.
module Sys

   # The ProcTable class encapsulates process table information.
   class ProcTable

      class Error < StandardError; end

      # There is no constructor
      private_class_method :new

      # The version of the sys-proctable library
      VERSION = '0.9.1'

      private

      PRNODEV = -1 # non-existent device

      @fields = [
         :flag,      # process flags (deprecated)
         :nlwp,      # number of active lwp's in the process
         :pid,       # unique process id
         :ppid,      # process id of parent
         :pgid,      # pid of session leader
         :sid,       # session id
         :uid,       # real user id
         :euid,      # effective user id
         :gid,       # real group id
         :egid,      # effective group id
         :addr,      # address of the process
         :size,      # size of process in kbytes
         :rssize,    # resident set size in kbytes
         :ttydev,    # tty device (or PRNODEV)
         :pctcpu,    # % of recent cpu used by all lwp's
         :pctmem,    # % of system memory used by process
         :start,     # absolute process start time
         :time,      # usr + sys cpu time for this process
         :ctime,     # usr + sys cpu time for reaped children
         :fname,     # name of the exec'd file
         :psargs,    # initial characters argument list - same as cmdline
         :wstat,     # if a zombie, the wait status
         :argc,      # initial argument count
         :argv,      # address of initial argument vector
         :envp,      # address of initial environment vector
         :dmodel,    # data model of the process
         :taskid,    # task id
         :projid,    # project id
         :nzomb,     # number of zombie lwp's in the process
         :poolid,    # pool id
         :zoneid,    # zone id
         :contract,  # process contract
         :lwpid,     # lwp id
         :wchan,     # wait address for sleeping lwp
         :stype,     # synchronization event type
         :state,     # numeric lwp state
         :sname,     # printable character for state
         :nice,      # nice for cpu usage
         :syscall,   # system call number (if in syscall)
         :pri,       # priority
         :clname,    # scheduling class name
         :name,      # name of system lwp
         :onpro,     # processor which last ran thsi lwp
         :bindpro,   # processor to which lwp is bound
         :bindpset,  # processor set to which lwp is bound
         :count,     # number of contributing lwp's
         :tstamp,    # current time stamp
         :create,    # process/lwp creation time stamp
         :term,      # process/lwp termination time stamp
         :rtime,     # total lwp real (elapsed) time
         :utime,     # user level cpu time
         :stime,     # system call cpu time
         :ttime,     # other system trap cpu time
         :tftime,    # text page fault sleep time
         :dftime,    # text page fault sleep time
         :kftime,    # kernel page fault sleep time
         :ltime,     # user lock wait sleep time
         :slptime,   # all other sleep time
         :wtime,     # wait-cpu (latency) time
         :stoptime,  # stopped time
         :minf,      # minor page faults
         :majf,      # major page faults
         :nswap,     # swaps
         :inblk,     # input blocks
         :oublk,     # output blocks
         :msnd,      # messages sent
         :mrcv,      # messages received
         :sigs,      # signals received
         :vctx,      # voluntary context switches
         :ictx,      # involuntary context switches
         :sysc,      # system calls
         :ioch,      # chars read and written
         :path,      # array of symbolic link paths from /proc/<pid>/path
         :contracts, # array symbolic link paths from /proc/<pid>/contracts
         :fd,        # array of used file descriptors
         :cmd_args,  # array of command line arguments
         :environ,   # hash of environment associated with the process,
         :cmdline    # joined cmd_args if present, otherwise psargs
      ]

      @psinfo_pack_directive = [
         'i',   # pr_flag
         'i',   # pr_nlwp
         'i',   # pr_pid
         'i',   # pr_ppid
         'i',   # pr_pgid
         'i',   # pr_sid
         'i',   # pr_uid
         'i',   # pr_euid
         'i',   # pr_gid
         'i',   # pr_egid
         'L',   # pr_addr
         'L',   # pr_size
         'L',   # pr_rssize
         'L',   # pr_pad1
         'i',   # pr_ttydev
         'S',   # pr_pctcpu
         'S',   # pr_pctmem
         'LL',  # pr_start
         'LL',  # pr_time
         'LL',  # pr_ctime
         'A16', # pr_fname[PRFNSZ]
         'A80', # pr_psargs[PRARGSZ]
         'i',   # pr_wstat
         'i',   # pr_argc
         'L',   # pr_argv
         'L',   # pr_envp
         'C',   # pr_dmodel
         'A3',  # pr_pad2[3]
         'i',   # pr_taskid
         'i',   # pr_projid
         'i',   # pr_nzomb
         'i',   # pr_poolid
         'i',   # pr_zoneid
         'i',   # pr_contract
         'i',   # pr_filler
         # --- LWPSINFO ---
         'i',   # pr_flag
         'i',   # pr_lwpid
         'L',   # pr_addr
         'L',   # pr_wchan
         'C',   # pr_stype
         'C',   # pr_state
         'A',   # pr_sname
         'C',   # pr_nice
         's',   # pr_syscall
         'C',   # pr_oldpri
         'C',   # pr_cpu
         'i',   # pr_pri
         'S',   # pr_pctcpu
         'S',   # pr_pad
         'LL',  # pr_start
         'LL',  # pr_time
         'A8',  # pr_clname[PRCLSZ]
         'A16', # pr_name[PRFNSZ]
         'i',   # pr_onpro
         'i',   # pr_bindpro
         'i',   # pr_bindpset
      ].join

      @prusage_pack_directive = [
         'i',     # pr_lwpid
         'i',     # pr_count
         'L2',    # pr_tstamp
         'L2',    # pr_create
         'L2',    # pr_term
         'L2',    # pr_rtime
         'L2',    # pr_utime
         'L2',    # pr_stime
         'L2',    # pr_ttime
         'L2',    # pr_tftime
         'L2',    # pr_dftime
         'L2',    # pr_kftime
         'L2',    # pr_ltime
         'L2',    # pr_slptime
         'L2',    # pr_wtime
         'L2',    # pr_stoptime
         'L12', # pr_filltime
         'L',     # pr_minf
         'L',     # pr_majf
         'L',     # pr_nswap
         'L',     # pr_inblk
         'L',     # pr_oublk
         'L',     # pr_msnd
         'L',     # pr_mrcv
         'L',     # pr_sigs
         'L',     # pr_vctx
         'L',     # pr_ictx
         'L',     # pr_sysc
         'L',     # pr_ioch
      ].join

      public

      ProcTableStruct = Struct.new("ProcTableStruct", *@fields) do
         alias comm fname
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
      #   p ProcTable.ps(1001)
      #
      def self.ps(pid = nil)
         raise TypeError unless pid.is_a?(Fixnum) if pid

         array  = block_given? ? nil : []
         struct = nil

         Dir.foreach("/proc") do |file|
            next if file =~ /\D/ # Skip non-numeric entries under /proc

            # Only return information for a given pid, if provided
            if pid
               next unless file.to_i == pid
            end

            # Skip over any entries we don't have permissions to read
            next unless File.readable?("/proc/#{file}/psinfo")

            psinfo = IO.read("/proc/#{file}/psinfo") rescue next

            psinfo_array = psinfo.unpack(@psinfo_pack_directive)

            struct = ProcTableStruct.new

            struct.flag   = psinfo_array[0]         # pr_flag
            struct.nlwp   = psinfo_array[1]         # pr_nlwp
            struct.pid    = psinfo_array[2]         # pr_pid
            struct.ppid   = psinfo_array[3]         # pr_ppid
            struct.pgid   = psinfo_array[4]         # pr_pgid
            struct.sid    = psinfo_array[5]         # pr_sid
            struct.uid    = psinfo_array[6]         # pr_uid
            struct.euid   = psinfo_array[7]         # pr_euid
            struct.gid    = psinfo_array[8]         # pr_gid
            struct.egid   = psinfo_array[9]         # pr_egid
            struct.addr   = psinfo_array[10]        # pr_addr
            struct.size   = psinfo_array[11] * 1024 # pr_size (in bytes)
            struct.rssize = psinfo_array[12] * 1024 # pr_rssize (in bytes)

            # skip pr_pad1

            struct.ttydev = psinfo_array[14] # pr_ttydev
            struct.pctcpu = (psinfo_array[15] * 100).to_f / 0x8000 # pr_pctcpu
            struct.pctmem = (psinfo_array[16] * 100).to_f / 0x8000 # pr_pctmem

            struct.start = Time.at(psinfo_array[17]) # pr_start (tv_sec)
            struct.time  = psinfo_array[19]          # pr_time (tv_sec)
            struct.ctime = psinfo_array[21]          # pr_ctime (tv_sec)

            struct.fname  = psinfo_array[23] # pr_fname
            struct.psargs = psinfo_array[24] # pr_psargs
            struct.wstat  = psinfo_array[25] # pr_wstat
            struct.argc   = psinfo_array[26] # pr_argc
            struct.argv   = psinfo_array[27] # pr_argv
            struct.envp   = psinfo_array[28] # pr_envp
            struct.dmodel = psinfo_array[29] # pr_dmodel

            # skip pr_pad2

            struct.taskid   = psinfo_array[31] # pr_taskid
            struct.projid   = psinfo_array[32] # pr_projid
            struct.nzomb    = psinfo_array[33] # pr_nzomb
            struct.poolid   = psinfo_array[34] # pr_poolid
            struct.zoneid   = psinfo_array[35] # pr_zoneid
            struct.contract = psinfo_array[36] # pr_contract

            # skip pr_filler

            ### LWPSINFO struct info

            # skip pr_flag

            struct.lwpid = psinfo_array[39] # pr_lwpid

            # skip pr_addr

            struct.wchan   = psinfo_array[41] # pr_wchan
            struct.stype   = psinfo_array[42] # pr_stype
            struct.state   = psinfo_array[43] # pr_state
            struct.sname   = psinfo_array[44] # pr_sname
            struct.nice    = psinfo_array[45] # pr_nice
            struct.syscall = psinfo_array[46] # pr_syscall

            # skip pr_oldpri
            # skip pr_cpu

            struct.pri = psinfo_array[49] # pr_pri

            # skip pr_pctcpu
            # skip pr_pad
            # skip pr_start
            # skip pr_time

            struct.clname   = psinfo_array[56] # pr_clname
            struct.name     = psinfo_array[57] # pr_name
            struct.onpro    = psinfo_array[58] # pr_onpro
            struct.bindpro  = psinfo_array[59] # pr_bindpro
            struct.bindpset = psinfo_array[60] # pr_bindpset

            # Get the full command line out of /proc/<pid>/as.
            begin
               File.open("/proc/#{file}/as") do |fd|
                  fd.sysseek(struct.argv, IO::SEEK_SET)
                  address = fd.sysread(struct.argc * 4).unpack("L")[0]

                  struct.cmd_args = []

                  0.upto(struct.argc - 1){ |i|
                     fd.sysseek(address, IO::SEEK_SET)
                     data = fd.sysread(128)[/^[^\0]*/] # Null strip
                     struct.cmd_args << data
                     address += data.length + 1 # Add 1 for the space
                  }

                  # Get the environment hash associated with the process.
                  struct.environ = {}

                  fd.sysseek(struct.envp, IO::SEEK_SET)

                  env_address = fd.sysread(128).unpack("L")[0]

                  # TODO: Optimization potential here.
                  loop do
                     fd.sysseek(env_address, IO::SEEK_SET)
                     data = fd.sysread(1024)[/^[^\0]*/] # Null strip
                     break if data.empty?
                     key, value = data.split('=')
                     struct.environ[key] = value
                     env_address += data.length + 1 # Add 1 for the space
                  end
               end
            rescue Errno::EACCES, Errno::EOVERFLOW, EOFError
               # Skip this if we don't have proper permissions, if there's
               # no associated environment, or if there's a largefile issue.
            rescue Errno::ENOENT
               next # The process has terminated. Bail out!
            end

            ### struct prusage

            begin
               prusage = 0.chr * 512
               prusage = IO.read("/proc/#{file}/usage")

               prusage_array = prusage.unpack(@prusage_pack_directive)

               # skip pr_lwpid
               struct.count    = prusage_array[1]
               struct.tstamp   = prusage_array[2]
               struct.create   = prusage_array[4]
               struct.term     = prusage_array[6]
               struct.rtime    = prusage_array[8]
               struct.utime    = prusage_array[10]
               struct.stime    = prusage_array[12]
               struct.ttime    = prusage_array[14]
               struct.tftime   = prusage_array[16]
               struct.dftime   = prusage_array[18]
               struct.kftime   = prusage_array[20]
               struct.ltime    = prusage_array[22]
               struct.slptime  = prusage_array[24]
               struct.wtime    = prusage_array[26]
               struct.stoptime = prusage_array[28]
               # skip filltime
               struct.minf     = prusage_array[42]
               struct.majf     = prusage_array[43]
               struct.nswap    = prusage_array[44]
               struct.inblk    = prusage_array[45]
               struct.oublk    = prusage_array[46]
               struct.msnd     = prusage_array[47]
               struct.mrcv     = prusage_array[48]
               struct.sigs     = prusage_array[49]
               struct.vctx     = prusage_array[50]
               struct.ictx     = prusage_array[51]
               struct.sysc     = prusage_array[52]
               struct.ioch     = prusage_array[53]
            rescue Errno::EACCES
               # Do nothing if we lack permissions. Just move on.
            rescue Errno::ENOENT
               next # The process has terminated. Bail out!
            end

            # Information from /proc/<pid>/path. This is represented as a hash,
            # with the symbolic link name as the key, and the file it links to
            # as the value, or nil if it cannot be found.
            #--
            # Note that cwd information can be gathered from here, too.
            struct.path = {}

            Dir["/proc/#{file}/path/*"].each{ |entry|
               link = File.readlink(entry) rescue nil
               struct.path[File.basename(entry)] = link
            }

            # Information from /proc/<pid>/contracts. This is represented as
            # a hash, with the symbolic link name as the key, and the file
            # it links to as the value.
            struct.contracts = {}

            Dir["/proc/#{file}/contracts/*"].each{ |entry|
               link = File.readlink(entry) rescue nil
               struct.contracts[File.basename(entry)] = link
            }

            # Information from /proc/<pid>/fd. This returns an array of
            # numeric file descriptors used by the process.
            struct.fd = Dir["/proc/#{file}/fd/*"].map{ |f| File.basename(f).to_i }

            # Use the cmd_args as the cmdline if available. Otherwise use
            # the psargs. This struct member is provided to provide a measure
            # of consistency with the other platform implementations.
            if struct.cmd_args && struct.cmd_args.length > 0
               struct.cmdline = struct.cmd_args.join(' ')
            else
               struct.cmdline = struct.psargs
            end

            # This is read-only data
            struct.freeze

            if block_given?
               yield struct
            else
               array << struct
            end
         end

         pid ? struct : array
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
         @fields.map{ |f| f.to_s }
      end
   end
end
