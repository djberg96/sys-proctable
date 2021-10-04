# frozen_string_literal: true

require 'win32ole'
require 'socket'
require 'date'
require 'sys/proctable/version'

# The Sys module serves as a namespace only
module Sys
  # The ProcTable class encapsulates process table information
  class ProcTable
    # There is no constructor
    private_class_method :new

    # Error typically raised if one of the Sys::ProcTable methods fails
    class Error < StandardError; end

    # The comm field corresponds to the 'name' field.  The 'cmdline' field
    # is the CommandLine attribute on Windows XP or later, or the
    # 'executable_path' field on Windows 2000 or earlier.
    #
    @fields = %w[
      caption
      cmdline
      comm
      creation_class_name
      creation_date
      cs_creation_class_name
      cs_name
      description
      executable_path
      execution_state
      handle
      handle_count
      install_date
      kernel_mode_time
      maximum_working_set_size
      minimum_working_set_size
      name
      os_creation_class_name
      os_name
      other_operation_count
      other_transfer_count
      page_faults
      page_file_usage
      ppid
      peak_page_file_usage
      peak_virtual_size
      peak_working_set_size
      priority
      private_page_count
      pid
      quota_non_paged_pool_usage
      quota_paged_pool_usage
      quota_peak_non_paged_pool_usage
      quota_peak_paged_pool_usage
      read_operation_count
      read_transfer_count
      session_id
      status
      termination_date
      thread_count
      user_mode_time
      virtual_size
      windows_version
      working_set_size
      write_operation_count
      write_transfer_count
    ]

    ProcTableStruct = Struct.new("ProcTableStruct", *@fields)

    # call-seq:
    #    ProcTable.fields
    #
    # Returns an array of fields that each ProcTableStruct will contain.  This
    # may be useful if you want to know in advance what fields are available
    # without having to perform at least one read of the /proc table.
    #
    class << self
      attr_reader :fields
    end

    # call-seq:
    #    ProcTable.ps(pid=nil)
    #    ProcTable.ps(pid=nil){ |ps| ... }
    #
    # In block form, yields a ProcTableStruct for each process entry that you
    # have rights to.  This method returns an array of ProcTableStruct's in
    # non-block form.
    #
    # If a +pid+ is provided, then only a single ProcTableStruct is yielded or
    # returned, or nil if no process information is found for that +pid+.
    #
    def self.ps(**kwargs)
      pid  = kwargs[:pid]
      host = kwargs[:host] || Socket.gethostname

      if pid && !pid.is_a?(Numeric)
        raise TypeError
      end

      array  = block_given? ? nil : []
      struct = nil

      begin
        wmi = WIN32OLE.connect("winmgmts://#{host}/root/cimv2")
      rescue WIN32OLERuntimeError => err
        raise Error, err # Re-raise as ProcTable::Error
      else
        wmi.InstancesOf("Win32_Process").each do |wproc|
          if pid && wproc.ProcessId != pid
            next
          end

          # Some fields are added later, and so are nil initially
          struct = ProcTableStruct.new(
            wproc.Caption,
            nil, # Added later, based on OS version
            wproc.Name,
            wproc.CreationClassName,
            parse_ms_date(wproc.CreationDate),
            wproc.CSCreationClassName,
            wproc.CSName,
            wproc.Description,
            wproc.ExecutablePath,
            wproc.ExecutionState,
            wproc.Handle,
            wproc.HandleCount,
            parse_ms_date(wproc.InstallDate),
            convert(wproc.KernelModeTime),
            wproc.MaximumWorkingSetSize,
            wproc.MinimumWorkingSetSize,
            wproc.Name,
            wproc.OSCreationClassName,
            wproc.OSName,
            convert(wproc.OtherOperationCount),
            convert(wproc.OtherTransferCount),
            wproc.PageFaults,
            wproc.PageFileUsage,
            wproc.ParentProcessId,
            convert(wproc.PeakPageFileUsage),
            convert(wproc.PeakVirtualSize),
            convert(wproc.PeakWorkingSetSize),
            wproc.Priority,
            convert(wproc.PrivatePageCount),
            wproc.ProcessId,
            wproc.QuotaNonPagedPoolUsage,
            wproc.QuotaPagedPoolUsage,
            wproc.QuotaPeakNonPagedPoolUsage,
            wproc.QuotaPeakPagedPoolUsage,
            convert(wproc.ReadOperationCount),
            convert(wproc.ReadTransferCount),
            wproc.SessionId,
            wproc.Status,
            parse_ms_date(wproc.TerminationDate),
            wproc.ThreadCount,
            convert(wproc.UserModeTime),
            convert(wproc.VirtualSize),
            wproc.WindowsVersion,
            convert(wproc.WorkingSetSize),
            convert(wproc.WriteOperationCount),
            convert(wproc.WriteTransferCount)
          )

          ###############################################################
          # On Windows XP or later, set the cmdline to the CommandLine
          # attribute.  Otherwise, set it to the ExecutablePath
          # attribute.
          ###############################################################
          if wproc.WindowsVersion.to_f < 5.1
            struct.cmdline = wproc.ExecutablePath
          else
            struct.cmdline = wproc.CommandLine
          end

          struct.freeze # This is read-only data

          if block_given?
            yield struct
          else
            array << struct
          end
        end
      end

      pid ? struct : array
    end

    #######################################################################
    # Converts a string in the format '20040703074625.015625-360' into a
    # Ruby Time object.
    #######################################################################
    def self.parse_ms_date(str)
      return if str.nil?
      DateTime.parse(str)
    end

    private_class_method :parse_ms_date

    #####################################################################
    # There is a bug in win32ole where uint64 types are returned as a
    # String instead of a Fixnum.  This method deals with that for now.
    #####################################################################
    def self.convert(str)
      return nil if str.nil? # Return nil, not 0
      str.to_i
    end

    private_class_method :convert
  end
end
