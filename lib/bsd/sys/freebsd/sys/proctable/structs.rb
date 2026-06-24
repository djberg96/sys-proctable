require 'ffi'
require_relative 'constants'

module Sys
  module ProcTableStructs
    extend FFI::Library

    class Timeval < FFI::Struct
      layout(:tv_sec, :time_t, :tv_usec, :suseconds_t)
    end

    class Priority < FFI::Struct
      layout(
        :pri_class, :uchar,
        :pri_level, :uchar,
        :pri_native, :uchar,
        :pri_user, :uchar
      )
    end

    class Rusage < FFI::Struct
      layout(
        :ru_utime, Timeval,
        :ru_stime, Timeval,
        :ru_maxrss, :long,
        :ru_ixrss, :long,
        :ru_idrss, :long,
        :ru_isrss, :long,
        :ru_minflt, :long,
        :ru_majflt, :long,
        :ru_nswap, :long,
        :ru_inblock, :long,
        :ru_oublock, :long,
        :ru_msgsnd, :long,
        :ru_msgrcv, :long,
        :ru_nsignals, :long,
        :ru_nvcsw, :long,
        :ru_nivcsw, :long
      )
    end

    class Pargs < FFI::Struct
      layout(
        :ar_ref, :uint,
        :ar_length, :uint,
        :ar_args, [:uchar, 1]
      )
    end

    class KInfoProc < FFI::Struct
      include Sys::ProcTableConstants

      def self.field_type(field)
        case field.name
          when :ki_groups
            [:gid_t, field.size / FFI.find_type(:gid_t).size]
          when :ki_size, :ki_tdev, :ki_oncpu, :ki_lastcpu
            unsigned_type(field.size)
          when :ki_wmesg, :ki_login, :ki_lockname, :ki_comm
            [:char, field.size]
          else
            FIELD_TYPES.fetch(field.name)
        end
      end

      def self.unsigned_type(size)
        {
          1 => :uchar,
          2 => :ushort,
          4 => :uint,
          8 => :uint64_t
        }.fetch(size)
      end

      def self.generated_layout
        require 'rbconfig'
        require 'ffi/tools/struct_generator'

        original_cc = ENV['CC']
        ENV['CC'] ||= RbConfig::CONFIG['CC']

        generator = FFI::StructGenerator.new('kinfo_proc') do |struct|
          struct.name 'struct kinfo_proc'
          struct.include 'sys/param.h'
          struct.include 'sys/user.h'

          FIELD_TYPES.each_key{ |field| struct.field(field) }
        end

        self.size = generator.size.to_i

        generator.fields.flat_map do |field|
          [field.name, field_type(field), field.offset]
        end
      ensure
        ENV['CC'] = original_cc
      end

      FIELD_TYPES = {
          :ki_pid => :pid_t,
          :ki_ppid => :pid_t,
          :ki_pgid => :pid_t,
          :ki_tpgid => :pid_t,
          :ki_sid => :pid_t,
          :ki_tsid => :pid_t,
          :ki_jobc => :short,
          :ki_uid => :uid_t,
          :ki_ruid => :uid_t,
          :ki_rgid => :gid_t,
          :ki_ngroups => :short,
          :ki_groups => nil,
          :ki_size => nil,
          :ki_rssize => :segsz_t,
          :ki_swrss => :segsz_t,
          :ki_tsize => :segsz_t,
          :ki_dsize => :segsz_t,
          :ki_ssize => :segsz_t,
          :ki_xstat => :u_short,
          :ki_acflag => :u_short,
          :ki_pctcpu => :fixpt_t,
          :ki_estcpu => :uint,
          :ki_slptime => :uint,
          :ki_swtime => :uint,
          :ki_runtime => :uint64_t,
          :ki_start => Timeval,
          :ki_flag => :long,
          :ki_stat => :char,
          :ki_nice => :char,
          :ki_lock => :char,
          :ki_rqindex => :char,
          :ki_oncpu => nil,
          :ki_lastcpu => nil,
          :ki_wmesg => nil,
          :ki_login => nil,
          :ki_lockname => nil,
          :ki_comm => nil,
          :ki_tdev => nil,
          :ki_jid => :int,
          :ki_pri => Priority,
          :ki_rusage => Rusage
      }.freeze

      layout(*generated_layout)
    end
  end
end
