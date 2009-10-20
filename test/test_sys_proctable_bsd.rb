################################################################
# test_sys_proctable_bsd.rb
#
# Test suite for various BSD flavors for the sys-proctable
# library. You should run these tests via 'rake test'.
################################################################
require 'rubygems'
gem 'test-unit'

require 'test/unit'
require 'sys/proctable'
require 'test/test_sys_proctable_all'
include Sys

class TC_Sys_ProcTable_BSD < Test::Unit::TestCase
   def self.startup
      @@fields = %w/
         pid ppid pgid ruid rgid comm state pctcpu oncpu ttynum ttydev
         wmesg time priority usrpri nice cmdline start
         maxrss ixrss idrss isrss minflt majflt nswap inblock oublock
         msgsnd msgrcv nsignals nvcsw nivcsw utime stime
      /
   end

   def setup
      @ptable = ProcTable.ps.last
   end

   def test_fields
      assert_respond_to(ProcTable, :fields)
      assert_kind_of(Array, ProcTable.fields)
      assert_equal(@@fields, ProcTable.fields)
   end

   def test_pid
      assert_respond_to(@ptable, :pid)
      assert_kind_of(Fixnum, @ptable.pid)
   end

   def test_ppid
      assert_respond_to(@ptable, :ppid)
      assert_kind_of(Fixnum, @ptable.ppid)
   end

   def test_pgid
      assert_respond_to(@ptable, :pgid)
      assert_kind_of(Fixnum, @ptable.pgid)
   end

   def test_ruid
      assert_respond_to(@ptable, :ruid)
      assert_kind_of(Fixnum, @ptable.ruid)
   end

   def test_rgid
      assert_respond_to(@ptable, :rgid)
      assert_kind_of(Fixnum, @ptable.rgid)
   end

   def test_comm
      assert_respond_to(@ptable, :comm)
      assert_kind_of(String, @ptable.comm)
   end

   def test_state
      assert_respond_to(@ptable, :state)
      assert_kind_of(String, @ptable.state)
   end

   def test_pctcpu
      assert_respond_to(@ptable, :pctcpu)
      assert_kind_of(Float, @ptable.pctcpu)
   end

   def test_oncpu
      assert_respond_to(@ptable, :oncpu)
      assert_kind_of(Fixnum, @ptable.oncpu)
   end

   def test_ttynum
      assert_respond_to(@ptable, :ttynum)
      assert_kind_of(Fixnum, @ptable.ttynum)
   end

   def test_ttydev
      assert_respond_to(@ptable, :ttydev)
      assert_kind_of(String, @ptable.ttydev)
   end

   def test_wmesg
      assert_respond_to(@ptable, :wmesg)
      assert_kind_of(String, @ptable.wmesg)
   end

   def test_time
      assert_respond_to(@ptable, :time)
      assert_kind_of(Fixnum, @ptable.time)
   end

   def test_priority
      assert_respond_to(@ptable, :priority)
      assert_kind_of(Fixnum, @ptable.priority)
   end

   def test_usrpri
      assert_respond_to(@ptable, :usrpri)
      assert_kind_of(Fixnum, @ptable.usrpri)
   end

   def test_nice
      assert_respond_to(@ptable, :nice)
      assert_kind_of(Fixnum, @ptable.nice)
   end

   def test_cmdline
      assert_respond_to(@ptable, :cmdline)
      assert_kind_of(String, @ptable.cmdline)
   end

   def test_start
      assert_respond_to(@ptable, :start)
      assert_kind_of(Time, @ptable.start)
   end

   def test_maxrss
      assert_respond_to(@ptable, :maxrss)
      assert_true(@ptable.maxrss.kind_of?(Fixnum) || @ptable.maxrss.nil?)
   end

   def test_ixrss
      assert_respond_to(@ptable, :ixrss)
      assert_true(@ptable.ixrss.kind_of?(Fixnum) || @ptable.ixrss.nil?)
   end

   def test_idrss
      assert_respond_to(@ptable, :idrss)
      assert_true(@ptable.idrss.kind_of?(Fixnum) || @ptable.idrss.nil?)
   end

   def test_isrss
      assert_respond_to(@ptable, :isrss)
      assert_true(@ptable.isrss.kind_of?(Fixnum) || @ptable.isrss.nil?)
   end

   def test_minflt
      assert_respond_to(@ptable, :minflt)
      assert_true(@ptable.minflt.kind_of?(Fixnum) || @ptable.minflt.nil?)
   end

   def test_majflt
      assert_respond_to(@ptable, :majflt)
      assert_true(@ptable.majflt.kind_of?(Fixnum) || @ptable.majflt.nil?)
   end

   def test_nswap
      assert_respond_to(@ptable, :nswap)
      assert_true(@ptable.nswap.kind_of?(Fixnum) || @ptable.nswap.nil?)
   end

   def test_inblock
      assert_respond_to(@ptable, :inblock)
      assert_true(@ptable.inblock.kind_of?(Fixnum) || @ptable.inblock.nil?)
   end

   def test_oublock
      assert_respond_to(@ptable, :oublock)
      assert_true(@ptable.oublock.kind_of?(Fixnum) || @ptable.oublock.nil?)
   end

   def test_msgsnd
      assert_respond_to(@ptable, :msgsnd)
      assert_true(@ptable.msgsnd.kind_of?(Fixnum) || @ptable.msgsnd.nil?)
   end

   def test_msgrcv
      assert_respond_to(@ptable, :msgrcv)
      assert_true(@ptable.msgrcv.kind_of?(Fixnum) || @ptable.msgrcv.nil?)
   end

   def test_nsignals
      assert_respond_to(@ptable, :nsignals)
      assert_true(@ptable.nsignals.kind_of?(Fixnum) || @ptable.nsignals.nil?)
   end

   def test_nvcsw
      assert_respond_to(@ptable, :nvcsw)
      assert_true(@ptable.nvcsw.kind_of?(Fixnum) || @ptable.nvcsw.nil?)
   end

   def test_nivcsw
      assert_respond_to(@ptable, :nivcsw)
      assert_true(@ptable.nivcsw.kind_of?(Fixnum) || @ptable.nivcsw.nil?)
   end

   def test_utime
      assert_respond_to(@ptable, :utime)
      assert_true(@ptable.utime.kind_of?(Fixnum) || @ptable.utime.nil?)
   end

   def test_stime
      assert_respond_to(@ptable, :stime)
      assert_true(@ptable.stime.kind_of?(Fixnum) || @ptable.stime.nil?)
   end

   def teardown
      @ptable = nil
   end

   def self.shutdown
      @@fields = nil
   end
end
