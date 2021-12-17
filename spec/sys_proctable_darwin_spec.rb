########################################################################
# sys_proctable_darwin_spec.rb
#
# Test suite for the Darwin version of the sys-proctable library. You
# should run these tests via the 'rake test' task.
########################################################################
require 'spec_helper'
require_relative 'sys_proctable_all_spec'

RSpec.describe Sys::ProcTable do
  let(:fields){
    %w[
      flags status xstatus pid ppid uid gid ruid rgid svuid svgid rfu1 comm
      name nfiles pgid pjobc tdev tpgid nice start_tvsec start_tvusec
      virtual_size resident_size total_user total_system threads_user
      threads_system policy faults pageins cow_faults messages_sent
      messages_received syscalls_mach syscalls_unix csw threadnum numrunning
      priority cmdline exe environ threadinfo
    ]
  }

  before(:all) do
    @pid1 = Process.spawn({'A' => 'B', 'Z' => nil}, "sleep 60")
    @pid2 = Process.spawn("ruby", "-Ilib", "-e", "sleep \'120\'.to_i", "--", "foo bar")
    sleep 1 # wait to make sure env is replaced by sleep
  end

  after(:all) do
    Process.kill('TERM', @pid1)
    Process.kill('TERM', @pid2)
  end

  context "fields singleton method" do
    it "responds to a fields method" do
      expect(described_class).to respond_to(:fields)
    end

    it "returns the expected results for the fields method" do
      expect(described_class.fields).to be_kind_of(Array)
      expect(described_class.fields).to eq(fields)
    end
  end

  context "ProcTable::Struct members" do
    subject { described_class.ps(pid: @pid1) }

    it "contains a pid member and returns the expected value" do
      expect(subject).to respond_to(:pid)
      expect(subject.pid).to be_kind_of(Numeric)
      expect(subject.pid).to eq(@pid1)
    end

    it "contains a ppid member and returns the expected value" do
      expect(subject).to respond_to(:ppid)
      expect(subject.ppid).to be_kind_of(Numeric)
      expect(subject.ppid).to eq(Process.pid)
    end

    it "contains a pgid member and returns the expected value" do
      expect(subject).to respond_to(:pgid)
      expect(subject.pgid).to be_kind_of(Numeric)
      expect(subject.pgid).to eq(Process.getpgrp)
    end

    it "contains a ruid member and returns the expected value" do
      expect(subject).to respond_to(:ruid)
      expect(subject.ruid).to be_kind_of(Numeric)
      expect(subject.ruid).to eq(Process.uid)
    end

    it "contains an rgid member and returns the expected value" do
      expect(subject).to respond_to(:rgid)
      expect(subject.rgid).to be_kind_of(Numeric)
      expect(subject.rgid).to eq(Process.gid)
    end

    it "contains an svuid member and returns the expected value" do
      expect(subject).to respond_to(:svuid)
      expect(subject.svuid).to be_kind_of(Numeric)
      expect(subject.svuid).to eq(Process.uid)
    end

    it "contains an svgid member and returns the expected value" do
      expect(subject).to respond_to(:svgid)
      expect(subject.svgid).to be_kind_of(Numeric)
      expect(subject.svgid).to eq(Process.gid)
    end

    it "contains a comm member and returns the expected value" do
      expect(subject).to respond_to(:comm)
      expect(subject.comm).to be_kind_of(String)
      expect(subject.comm).to eq('sleep')
    end

    it "contains a cmdline member and returns the expected value" do
      expect(subject).to respond_to(:cmdline)
      expect(subject.cmdline).to be_kind_of(String)
      expect(subject.cmdline).to eq('sleep 60')
    end

    it "returns a string with the expected arguments for the cmdline member", :skip => :jruby do
      ptable = Sys::ProcTable.ps(pid: @pid2)
      expect(ptable.cmdline).to eq('ruby -Ilib -e sleep \'120\'.to_i -- foo bar')
    end

    it "contains an exe member and returns the expected value" do
      expect(subject).to respond_to(:exe)
      expect(subject.exe).to be_kind_of(String)
      expect(subject.exe).to eq(`which sleep`.chomp)
    end

    it "contains an environ member and returns the expected value" do
      skip "It appears to no longer be possible to get environ on spawned processes on Catalina or later in most cases"
      expect(subject).to respond_to(:environ)
      expect(subject.environ).to be_kind_of(Hash)
      expect(subject.environ['A']).to eq('B')
      expect(subject.environ['Z']).to be_nil
    end
  end

  context "private constants" do
    it "makes FFI methods private" do
      expect(described_class).not_to respond_to(:sysctl)
      expect(described_class).not_to respond_to(:proc_listallpids)
      expect(described_class).not_to respond_to(:proc_pidinfo)
    end

    it "makes FFI structs private" do
      expect(described_class.constants).not_to include(:ProcBsdInfo)
      expect(described_class.constants).not_to include(:ProcThreadInfo)
      expect(described_class.constants).not_to include(:ProcTaskInfo)
      expect(described_class.constants).not_to include(:ProcTaskAllInfo)
    end

    it "makes internal constants private" do
      expect(described_class.constants).not_to include(:PROC_PIDTASKALLINFO)
      expect(described_class.constants).not_to include(:PROC_PIDTHREADINFO)
      expect(described_class.constants).not_to include(:PROC_PIDLISTTHREADS)
      expect(described_class.constants).not_to include(:CTL_KERN)
      expect(described_class.constants).not_to include(:KERN_PROCARGS)
      expect(described_class.constants).not_to include(:KERN_PROCARGS2)
      expect(described_class.constants).not_to include(:MAX_COMLEN)
      expect(described_class.constants).not_to include(:MAX_PATHLEN)
      expect(described_class.constants).not_to include(:MAXTHREADNAMESIZE)
      expect(described_class.constants).not_to include(:PROC_PIDPATHINFO_MAXSIZE)
    end
  end
end
