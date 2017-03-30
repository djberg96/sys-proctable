##############################################################################
# test_sys_top.rb
#
# Test suite for the sys-top library that is included with this distribution.
#
# Tests omitted on OSX until I figure out how to get pctcpu information.
##############################################################################
require 'test-unit'
require 'sys/top'

class TC_Top < Test::Unit::TestCase
  include Sys

  test "top version" do
    assert_equal('1.0.5', Top::VERSION)
  end

  test "top basic functionality" do
    assert_respond_to(Top, :top)
  end

  test "top works with no arguments" do
    assert_nothing_raised{ Top.top }
  end

  test "top accepts optional arguments" do
    assert_nothing_raised{ Top.top(5) }
    assert_nothing_raised{ Top.top(5, 'cmdline') }
  end

  test "top with no arguments returns expected results" do
    assert_equal(10, Top.top.length)
    assert_kind_of(Struct::ProcTableStruct, Top.top.first)
  end

  test "top with size argument returns expected result" do
    assert_equal(5, Top.top(5).length)
  end

  test "top with size and sort_by argument returns expected result" do
    assert_equal(5, Top.top(5, :cmdline).length)
  end

  test "top returns an array" do
    assert_kind_of(Array, Top.top)
  end

  test "top accepts a maximum of two arguments" do
    assert_raises(ArgumentError){ Top.top(1, 'foo', 2) }
  end
end
