########################################################################
# test_sys_proctable_darwin.rb
#
# Test suite for the Darwin version of the sys-proctable library. You
# should run these tests via the 'rake test' task.
########################################################################
require 'rubygems'
gem 'test-unit'

require 'sys/proctable'
require 'test/test_sys_proctable_all'
include Sys

class TC_ProcTable_Darwin < Test::Unit::TestCase
  def self.startup
    @@fields = %w/
      pid ppid pgid ruid rgid comm state pctcpu oncpu tnum
      tdev wmesg rtime priority usrpri nice cmdline starttime
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
    assert_true(@ptable.comm.length > 0)
  end

  def test_state
    assert_respond_to(@ptable, :state)
    assert_kind_of(String, @ptable.state)
    assert_true(%w/idle run sleep stop zombie unknown/.include?(@ptable.state))
  end

  def test_pctcpu
    assert_respond_to(@ptable, :pctcpu)
    assert_kind_of(Float, @ptable.pctcpu)
  end

  def test_oncpu
    assert_respond_to(@ptable, :oncpu)
    omit("oncpu always nil for now")
  end

  def test_tnum
    assert_respond_to(@ptable, :tnum)
    #assert_kind_of(Fixnum, @ptable.tnum)
  end

  def test_tdev
    assert_respond_to(@ptable, :tdev)
    #assert_kind_of(String, @ptable.tdev)
  end

  def test_wmesg
    assert_respond_to(@ptable, :wmesg)
    assert_kind_of(String, @ptable.wmesg)
  end

  def test_rtime
    assert_respond_to(@ptable, :rtime)
    assert_kind_of(Fixnum, @ptable.rtime)
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

  def test_starttime
    assert_respond_to(@ptable, :starttime)
    assert_kind_of(Time, @ptable.starttime)
  end

  def test_maxrss
    assert_respond_to(@ptable, :maxrss)
    assert_true([NilClass, Fixnum].include?(@ptable.maxrss.class))
  end

  def test_ixrss
    assert_respond_to(@ptable, :ixrss)
    assert_true([NilClass, Fixnum].include?(@ptable.ixrss.class))
  end

  def test_idrss
    assert_respond_to(@ptable, :idrss)
    assert_true([NilClass, Fixnum].include?(@ptable.idrss.class))
  end

  def test_isrss
    assert_respond_to(@ptable, :isrss)
    assert_true([NilClass, Fixnum].include?(@ptable.isrss.class))
  end

  def test_minflt
    assert_respond_to(@ptable, :minflt)
    assert_true([NilClass, Fixnum].include?(@ptable.minflt.class))
  end

  def test_majflt
    assert_respond_to(@ptable, :majflt)
    assert_true([NilClass, Fixnum].include?(@ptable.majflt.class))
  end

  def test_nswap
    assert_respond_to(@ptable, :nswap)
    assert_true([NilClass, Fixnum].include?(@ptable.nswap.class))
  end

  def test_inblock
    assert_respond_to(@ptable, :inblock)
    assert_true([NilClass, Fixnum].include?(@ptable.inblock.class))
  end

  def test_oublock
    assert_respond_to(@ptable, :oublock)
    assert_true([NilClass, Fixnum].include?(@ptable.oublock.class))
  end

  def test_msgsnd
    assert_respond_to(@ptable, :msgsnd)
    assert_true([NilClass, Fixnum].include?(@ptable.msgsnd.class))
  end

  def test_msgrcv
    assert_respond_to(@ptable, :msgrcv)
    assert_true([NilClass, Fixnum].include?(@ptable.msgrcv.class))
  end

  def test_nsignals
    assert_respond_to(@ptable, :nsignals)
    assert_true([NilClass, Fixnum].include?(@ptable.nsignals.class))
  end

  def test_nvcsw
    assert_respond_to(@ptable, :nvcsw)
    assert_true([NilClass, Fixnum].include?(@ptable.nvcsw.class))
  end

  def test_nivcsw
    assert_respond_to(@ptable, :nivcsw)
    assert_true([NilClass, Fixnum].include?(@ptable.nivcsw.class))
  end

  def test_utime
    assert_respond_to(@ptable, :utime)
    assert_true([NilClass, Fixnum].include?(@ptable.utime.class))
  end

  def test_stime
    assert_respond_to(@ptable, :stime)
    assert_true([NilClass, Fixnum].include?(@ptable.stime.class))
  end

  def teardown
    @ptable = nil
  end

  def self.shutdown
    @@fields = nil
  end
end
