# frozen_string_literal: true

require 'sys/proctable/version'
require_relative 'proctable/cgroup_entry'
require_relative 'proctable/smaps'

# The Sys module serves as a namespace only.
module Sys
  # The ProcTable class encapsulates process table information.
  class ProcTable
    # Error typically raised if the ProcTable.ps method fails.
    class Error < StandardError; end

    # There is no constructor
    private_class_method :new

    @mem_total = File.read("/proc/meminfo")[/MemTotal.*/].split[1].to_i * 1024 rescue nil
    @boot_time = File.read("/proc/stat")[/btime.*/].split.last.to_i rescue nil

    @fields = [
      'cmdline',               # Complete command line
      'cwd',                   # Current working directory
      'environ',               # Environment
      'exe',                   # Actual pathname of the executed command
      'fd',                    # File descriptors open by process
      'root',                  # Root directory of process
      'pid',                   # Process ID
      'comm',                  # Filename of executable
      'state',                 # Single character state abbreviation
      'ppid',                  # Parent process ID
      'pgrp',                  # Process group
      'session',               # Session ID
      'tty_nr',                # TTY (terminal) associated with the process
      'tpgid',                 # Group ID of the TTY
      'flags',                 # Kernel flags
      'minflt',                # Number of minor faults
      'cminflt',               # Number of minor faults of waited-for children
      'majflt',                # Number of major faults
      'cmajflt',               # Number of major faults of waited-for children
      'utime',                 # Number of user mode jiffies
      'stime',                 # Number of kernel mode jiffies
      'cutime',                # Number of children's user mode jiffies
      'cstime',                # Number of children's kernel mode jiffies
      'priority',              # Nice value plus 15
      'nice',                  # Nice value
      'num_threads',           # Number of threads in this process
      'itrealvalue',           # Time in jiffies before next SIGALRM
      'starttime',             # Time in jiffies since system boot
      'vsize',                 # Virtual memory size in bytes
      'rss',                   # Resident set size
      'rlim',                  # Current limit on the rss in bytes (old)
      'rsslim',                # Current limit on the rss in bytes (current)
      'startcode',             # Address above which program text can run
      'endcode',               # Address below which program text can run
      'startstack',            # Address of the startstack
      'kstkesp',               # Kernel stack page address
      'kstkeip',               # Kernel instruction pointer
      'signal',                # Bitmap of pending signals
      'blocked',               # Bitmap of blocked signals
      'sigignore',             # Bitmap of ignored signals
      'sigcatch',              # Bitmap of caught signals
      'wchan',                 # Channel in which the process is waiting
      'nswap',                 # Number of pages swapped
      'cnswap',                # Cumulative nswap for child processes
      'exit_signal',           # Signal to be sent to parent when process dies
      'processor',             # CPU number last executed on
      'rt_priority',           # Real time scheduling priority
      'policy',                # Scheduling policy
      'delayacct_blkio_ticks', # Aggregated block I/O delays
      'guest_time',            # Guest time of the process
      'cguest_time',           # Guest time of the process's children
      'name',                  # Process name
      'uid',                   # Real user ID
      'euid',                  # Effective user ID
      'gid',                   # Real group ID
      'egid',                  # Effective group ID
      'pctcpu',                # Percent of CPU usage (custom field)
      'pctmem',                # Percent of Memory usage (custom field)
      'nlwp',                  # Number of Light-Weight Processes associated with the process (threads)
      'cgroup',                # Control groups to which the process belongs
      'smaps'                  # Process memory size for all mapped files
    ]

    ProcTableStruct = Struct.new('ProcTableStruct', *@fields)

    private_constant :ProcTableStruct

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
    #   # Skip smaps collection and/or cgroup collection
    #   p ProcTable.ps(smaps: false, cgroup: false)
    #
    #--
    #  It's possible that a process could terminate while gathering
    #  information for that process. When that happens, this library
    #  will simply skip to the next record. In short, this library will
    #  either return all information for a process, or none at all.
    #
    def self.ps(**kwargs)
      pid    = kwargs[:pid]
      smaps  = kwargs[:smaps]
      cgroup = kwargs[:cgroup]

      array  = block_given? ? nil : []
      struct = nil

      raise TypeError if pid && !pid.is_a?(Numeric)

      Dir.foreach("/proc") do |file|
        next if file =~ /\D/ # Skip non-numeric directories
        next if pid && file.to_i != pid

        struct = ProcTableStruct.new

        # Get /proc/<pid>/cmdline information. Strip out embedded nulls.
        begin
          data = File.read("/proc/#{file}/cmdline").tr("\000", ' ').strip
          struct.cmdline = data
        rescue StandardError
          next # Process terminated, on to the next process
        end

        # Get /proc/<pid>/cwd information
        struct.cwd = File.readlink("/proc/#{file}/cwd") rescue nil

        # Get /proc/<pid>/environ information. Environment information
        # is represented as a Hash, with the environment variable as the
        # key and its value as the hash value.
        struct.environ = {}

        begin
          File.read("/proc/#{file}/environ").force_encoding("UTF-8").split("\0").each do |str|
            key, value = str.split('=')
            struct.environ[key] = value
          end
        rescue Errno::EACCES, Errno::ESRCH, Errno::ENOENT
          # Ignore and move on.
        end

        # Get /proc/<pid>/exe information
        struct.exe = File.readlink("/proc/#{file}/exe") rescue nil

        # Get /proc/<pid>/fd information. File descriptor information
        # is represented as a Hash, with the fd as the key, and its
        # symlink as the value.
        struct.fd = {}

        begin
          Dir["/proc/#{file}/fd/*"].each do |fd|
            struct.fd[File.basename(fd)] = File.readlink(fd) rescue nil
          end
        rescue StandardError
          # Ignore and move on
        end

        # Get /proc/<pid>/root information
        struct.root = File.readlink("/proc/#{file}/root") rescue nil

        # Get /proc/<pid>/stat information
        stat = File.read("/proc/#{file}/stat") rescue next

        # Get number of LWP, one directory for each in /proc/<pid>/task/
        # Every process has at least one thread, so if we fail to read the task directory, set nlwp to 1.
        struct.nlwp = Dir.glob("/proc/#{file}/task/*").length rescue struct.nlwp = 1

        # Get control groups to which the process belongs
        unless cgroup == false
          struct.cgroup = File.readlines("/proc/#{file}/cgroup").map { |l| CgroupEntry.new(l) } rescue []
        end

        # Read smaps, returning a parsable string if we don't have permissions.
        # Note: We're blindly rescuing because File.readable?/readable_real?
        # are true for a file in the /proc fileystem but raises a Errno:EACCESS
        # when your try to read it without permissions.
        unless smaps == false
          smaps_contents = File.read("/proc/#{file}/smaps") rescue ""
          struct.smaps = Smaps.new(file, smaps_contents)
        end

        # Deal with spaces in comm name. This isn't supposed to happen, but in
        # rare cases - the original offending case was "(xzen thread)" - it can
        # occur. So we parse it out, replace the spaces with hyphens, and
        # re-insert it into the stat string so that it splits properly later on.
        #
        # Courtesy of Ara Howard.
        #
        re = /\([^)]+\)/
        comm = stat[re]
        comm.tr!(' ', '-')
        stat[re] = comm

        stat = stat.split

        struct.pid                   = stat[0].to_i
        struct.comm                  = stat[1].tr('()', '') # Remove parens
        struct.state                 = stat[2]
        struct.ppid                  = stat[3].to_i
        struct.pgrp                  = stat[4].to_i
        struct.session               = stat[5].to_i
        struct.tty_nr                = stat[6].to_i
        struct.tpgid                 = stat[7].to_i
        struct.flags                 = stat[8].to_i
        struct.minflt                = stat[9].to_i
        struct.cminflt               = stat[10].to_i
        struct.majflt                = stat[11].to_i
        struct.cmajflt               = stat[12].to_i
        struct.utime                 = stat[13].to_i
        struct.stime                 = stat[14].to_i
        struct.cutime                = stat[15].to_i
        struct.cstime                = stat[16].to_i
        struct.priority              = stat[17].to_i
        struct.nice                  = stat[18].to_i
        struct.num_threads           = stat[19].to_i
        struct.itrealvalue           = stat[20].to_i
        struct.starttime             = stat[21].to_i
        struct.vsize                 = stat[22].to_i
        struct.rss                   = stat[23].to_i
        struct.rlim                  = stat[24].to_i # Old name for backwards compatibility
        struct.rsslim                = stat[24].to_i
        struct.startcode             = stat[25].to_i
        struct.endcode               = stat[26].to_i
        struct.startstack            = stat[27].to_i
        struct.kstkesp               = stat[28].to_i
        struct.kstkeip               = stat[29].to_i
        struct.signal                = stat[30].to_i
        struct.blocked               = stat[31].to_i
        struct.sigignore             = stat[32].to_i
        struct.sigcatch              = stat[33].to_i
        struct.wchan                 = stat[34].to_i
        struct.nswap                 = stat[35].to_i
        struct.cnswap                = stat[36].to_i
        struct.exit_signal           = stat[37].to_i
        struct.processor             = stat[38].to_i
        struct.rt_priority           = stat[39].to_i
        struct.policy                = stat[40].to_i
        struct.delayacct_blkio_ticks = stat[41].to_i
        struct.guest_time            = stat[42].to_i
        struct.cguest_time           = stat[43].to_i

        # Get /proc/<pid>/status information (name, uid, euid, gid, egid)
        begin
          File.foreach("/proc/#{file}/status") do |line|
            case line
              when /Name:\s*?(\w+)/
                struct.name = Regexp.last_match(1)
              when /Uid:\s*?(\d+)\s*?(\d+)/
                struct.uid  = Regexp.last_match(1).to_i
                struct.euid = Regexp.last_match(2).to_i
              when /Gid:\s*?(\d+)\s*?(\d+)/
                struct.gid  = Regexp.last_match(1).to_i
                struct.egid = Regexp.last_match(2).to_i
            end
          end
        rescue Errno::ESRCH, Errno::ENOENT
          next
        end

        # If cmdline is empty use comm instead
        struct.cmdline = struct.comm if struct.cmdline.empty?

        # Manually calculate CPU and memory usage
        struct.pctcpu = get_pctcpu(struct.utime, struct.starttime)
        struct.pctmem = get_pctmem(struct.rss)

        struct.freeze # This is read-only data

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
    class << self
      attr_reader :fields
    end

    # Calculate the percentage of memory usage for the given process.
    #
    def self.get_pctmem(rss)
      return nil unless @mem_total
      page_size = 4096
      rss_total = rss * page_size
      format("%3.2f", (rss_total.to_f / @mem_total) * 100).to_f
    end

    private_class_method :get_pctmem

    # Calculate the percentage of CPU usage for the given process.
    #
    def self.get_pctcpu(utime, start_time)
      return nil unless @boot_time
      hertz = 100.0
      utime = (utime * 10000).to_f
      stime = (start_time.to_f / hertz) + @boot_time
      format("%3.2f", (utime / 10000.0) / (Time.now.to_i - stime)).to_f
    end

    private_class_method :get_pctcpu
  end
end
