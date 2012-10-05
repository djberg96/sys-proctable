#######################################################################
# test_sys_proctable_all.rb
#
# Test suite for methods common to all platforms. Generally speaking
# you should run this test case using the 'rake test' task.
#######################################################################
require 'rubygems'
gem 'test-unit'

require 'test/unit'
require 'sys/proctable'
require 'test/test_sys_top'
include Sys

class TC_ProcTable_All < Test::Unit::TestCase
  def self.startup
    @@windows = File::ALT_SEPARATOR
  end

  def setup
    @pid = @@windows ? 0 : 1
  end

  def test_version
    assert_equal('0.9.2', ProcTable::VERSION)
  end

  def test_fields
    assert_respond_to(ProcTable, :fields)
    assert_nothing_raised{ ProcTable.fields }
    assert_kind_of(Array, ProcTable.fields)
    assert_kind_of(String, ProcTable.fields.first)
  end

  def test_ps
    assert_respond_to(ProcTable, :ps)
    assert_nothing_raised{ ProcTable.ps }
    assert_nothing_raised{ ProcTable.ps{} }
  end

  def test_ps_with_pid
    assert_nothing_raised{ ProcTable.ps(0) }
  end

  def test_ps_with_explicit_nil
    assert_nothing_raised{ ProcTable.ps(nil) }
    assert_kind_of(Array, ProcTable.ps(nil))
  end

  def test_ps_return_value
    assert_kind_of(Array, ProcTable.ps)
    assert_kind_of(Struct::ProcTableStruct, ProcTable.ps(@pid))
    assert_equal(nil, ProcTable.ps(999999999))
    assert_equal(nil, ProcTable.ps(999999999){})
    assert_equal(nil, ProcTable.ps{})
  end

  def test_ps_returned_struct_is_frozen
    assert_true(ProcTable.ps.first.frozen?)
  end

  def test_ps_expected_errors
    assert_raises(TypeError){ ProcTable.ps('vim') }
    omit_if(@@windows, 'ArgumentError check skipped on MS Windows')
    assert_raises(ArgumentError){ ProcTable.ps(0, 'localhost') }
  end

  def test_new_not_allowed
    assert_raise(NoMethodError){ Sys::ProcTable.new }
  end

  def test_error_class_defined
    assert_not_nil(Sys::ProcTable::Error)
    assert_kind_of(StandardError, Sys::ProcTable::Error.new)
  end

  def teardown
    @pid  = nil
  end

  def self.teardown
    @@windows = nil
  end
end
