#######################################################################
# sys_proctable_all_spec.rb
#
# Test suite for methods common to all platforms. Generally speaking
# you should run these specs using the 'rake spec' task.
#######################################################################
require 'spec_helper'

RSpec.describe 'common' do
  let(:windows) { File::ALT_SEPARATOR }

  before(:all) do
    @pid = Process.pid
  end

  context 'constants' do
    it 'has a VERSION constant set to the expected value' do
      expect(Sys::ProcTable::VERSION).to eql('1.3.0')
      expect(Sys::ProcTable::VERSION).to be_frozen
    end

    it 'defines a custom error class' do
      expect{ Sys::ProcTable::Error }.not_to raise_error
      expect(Sys::ProcTable::Error.new).to be_kind_of(StandardError)
    end
  end

  context 'fields' do
    it 'has a fields singleton method' do
      expect(Sys::ProcTable).to respond_to(:fields)
    end

    it 'returns the expected data type for the fields singleton method' do
      expect(Sys::ProcTable.fields).to be_kind_of(Array)
      expect(Sys::ProcTable.fields.first).to be_kind_of(String)
    end
  end

  context 'ps' do
    it 'defines a ps singleton method' do
      expect(Sys::ProcTable).to respond_to(:ps)
    end

    it 'allows a pid option as an argument' do
      expect{ Sys::ProcTable.ps(:pid => 0) }.not_to raise_error
    end

    it 'allows the pid to be nil' do
      expect{ Sys::ProcTable.ps(:pid => nil) }.not_to raise_error
      expect(Sys::ProcTable.ps(:pid => nil)).to be_kind_of(Array)
    end

    it 'returns expected results with no arguments' do
      expect(Sys::ProcTable.ps).to be_kind_of(Array)
    end

    it 'returns expected results with a pid argument' do
      expect(Sys::ProcTable.ps(:pid => @pid)).to be_kind_of(Struct::ProcTableStruct)
    end

    it 'returns nil if the process does not exist' do
      expect(Sys::ProcTable.ps(:pid => 999999999)).to be_nil
    end

    it 'returns nil in block form whether or not a pid was provided' do
      expect(Sys::ProcTable.ps{}).to be_nil
      expect(Sys::ProcTable.ps(:pid => 999999999){}).to be_nil
    end

    it 'returns frozen structs' do
      expect(Sys::ProcTable.ps.first.frozen?).to be(true)
    end

    it 'expects a numeric pid argument if present' do
      expect{ Sys::ProcTable.ps(:pid => 'vim') }.to raise_error(TypeError)
    end

    it 'accepts keyword arguments only' do
      expect{ Sys::ProcTable.ps(0, 'localhost') }.to raise_error(ArgumentError)
    end

    it 'disables the traditional constructor' do
      expect{ Sys::ProcTable.new }.to raise_error(NoMethodError)
    end

    it 'works within a thread' do
      expect{ Thread.new{ Sys::ProcTable.ps }.value }.not_to raise_error
    end
  end
end
