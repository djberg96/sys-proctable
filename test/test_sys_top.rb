##############################################################################
# test_sys_top.rb
#
# Test suite for the sys-top library that is included with this distribution.
##############################################################################
require 'rubygems'
gem 'test-unit'

require 'test/unit'
require 'sys/top'
include Sys

class TC_Top < Test::Unit::TestCase
   def test_version
      assert_equal('1.0.2', Top::VERSION)
   end

   def test_top_basic
      assert_respond_to(Top, :top)
      assert_nothing_raised{ Top.top }
      assert_nothing_raised{ Top.top(5) }
      assert_nothing_raised{ Top.top(5, 'cmdline') }
   end

   def test_top
      assert_equal(10, Top.top.length)
      assert_kind_of(Struct::ProcTableStruct, Top.top.first)
   end

   def test_top_with_size
      assert_equal(5, Top.top(5).length)
   end

   def test_top_with_size_and_sort_by_field
      assert_equal(5, Top.top(5, :cmdline).length)
   end

   def test_top_return_type
      assert_kind_of(Array, Top.top)
   end

   def test_top_expected_errors
      assert_raises(ArgumentError){ Top.top(1, 'foo', 2) }
   end
end
