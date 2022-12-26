#######################################################################
# sys_proctable_sunos_spec.rb
#
# Test suite for sys-proctable for SunOS/Solaris. This should be run
# run via the 'rake spec' task.
#######################################################################
require 'spec_helper'

RSpec.describe Sys::ProcTable, :sunos do
  let(:fields){
    %w[
        flag nlwp pid ppid pgid sid uid euid gid egid addr size
        rssize ttydev pctcpu pctmem start time ctime fname psargs
        wstat argc argv envp dmodel taskid projid nzomb poolid
        zoneid contract lwpid wchan stype state sname nice syscall
        pri clname name onpro bindpro bindpset count tstamp create
        term rtime utime stime ttime tftime dftime kftime ltime
        slptime wtime stoptime minf majf nswap inblk oublk msnd
        mrcv sigs vctx ictx sysc ioch path contracts fd cmd_args
        environ cmdline
      ]
  }

  context 'fields singleton method' do
    it 'responds to a fields method' do
      expect(described_class).to respond_to(:fields)
    end

    it 'returns the expected results for the fields method' do
      expect(described_class.fields).to be_kind_of(Array)
      expect(described_class.fields).to eql(fields)
    end
  end

  context 'ProcTable::Struct members' do
    subject(:process){ described_class.ps(:pid => Process.pid) }

    it 'contains a pid member and returns the expected value' do
      expect(process).to respond_to(:pid)
      expect(process.pid).to be_kind_of(Numeric)
      expect(process.pid).to eql(Process.pid)
    end

    it 'contains a ppid member and returns the expected value' do
      expect(process).to respond_to(:ppid)
      expect(process.ppid).to be_kind_of(Numeric)
      expect(process.ppid).to eql(Process.ppid)
    end

    it 'contains a pgid member and returns the expected value' do
      expect(process).to respond_to(:pgid)
      expect(process.pgid).to be_kind_of(Numeric)
      expect(process.pgid).to eql(Process.getpgrp)
    end

    it 'has a flag member that returns the expected value' do
      expect(process).to respond_to(:flag)
      expect(process.flag).to be_kind_of(Integer)
    end

    it 'has an nlwp member that returns the expected value' do
      expect(process).to respond_to(:nlwp)
      expect(process.nlwp).to be_kind_of(Integer)
      expect(process.nlwp).to be >= 0
    end

    it 'has a sid member that returns the expected value' do
      expect(process).to respond_to(:sid)
      expect(process.sid).to be_kind_of(Integer)
      expect(process.sid).to be >= 0
    end

    it 'has a uid member that returns the expected value' do
      expect(process).to respond_to(:uid)
      expect(process.uid).to be_kind_of(Integer)
      expect(process.uid).to eql(Process.uid)
    end

    it 'has a euid member that returns the expected value' do
      expect(process).to respond_to(:euid)
      expect(process.euid).to be_kind_of(Integer)
      expect(process.euid).to eql(Process.euid)
    end

    it 'has a gid member that returns the expected value' do
      expect(process).to respond_to(:gid)
      expect(process.gid).to be_kind_of(Integer)
      expect(process.gid).to eql(Process.gid)
    end

    it 'has a egid member that returns the expected value' do
      expect(process).to respond_to(:egid)
      expect(process.egid).to be_kind_of(Integer)
      expect(process.egid).to eql(Process.egid)
    end

    it 'has an addr member that returns the expected value' do
      expect(process).to respond_to(:addr)
      expect(process.addr).to be_kind_of(Integer)
      expect(process.addr).to be >= 0
    end

    it 'has a size member that returns the expected value' do
      expect(process).to respond_to(:size)
      expect(process.size).to be_kind_of(Integer)
      expect(process.size).to be >= 0
    end

    it 'has a rssize member that returns the expected value' do
      expect(process).to respond_to(:rssize)
      expect(process.rssize).to be_kind_of(Integer)
      expect(process.rssize).to be >= 0
    end

    it 'has a ttydev member that returns the expected value' do
      expect(process).to respond_to(:ttydev)
      expect(process.ttydev).to be_kind_of(Integer)
      expect(process.ttydev).to be >= -1
    end

    it 'has a pctcpu member that returns the expected value' do
      expect(process).to respond_to(:pctcpu)
      expect(process.pctcpu).to be_kind_of(Float)
      expect(process.pctcpu).to be >= 0.0
    end

    it 'has a pctmem member that returns the expected value' do
      expect(process).to respond_to(:pctmem)
      expect(process.pctmem).to be_kind_of(Float)
      expect(process.pctmem).to be >= 0.0
    end

    it 'has a start member that returns the expected value' do
      expect(process).to respond_to(:start)
      expect(process.start).to be_kind_of(Time)
    end

    it 'has a time member that returns the expected value' do
      expect(process).to respond_to(:time)
      expect(process.time).to be_kind_of(Integer)
      expect(process.time).to be >= 0
    end

    it 'has a ctime member that returns the expected value' do
      expect(process).to respond_to(:ctime)
      expect(process.ctime).to be_kind_of(Integer)
      expect(process.ctime).to be >= 0
    end

    it 'has a fname member that returns the expected value' do
      expect(process).to respond_to(:fname)
      expect(process.fname).to be_kind_of(String)
      expect(process.fname.size).to be > 0
    end

    it 'has a comm alias member' do
      expect(process.method(:comm)).to eql(process.method(:fname))
    end

    it 'has a psargs member that returns the expected value' do
      expect(process).to respond_to(:psargs)
      expect(process.psargs).to be_kind_of(String)
      expect(process.psargs.size).to be > 0
    end

    it 'has a wstat member that returns the expected value' do
      expect(process).to respond_to(:wstat)
      expect(process.wstat).to be_kind_of(Integer)
      expect(process.wstat).to be >= 0
    end

    it 'has an args member that returns the expected value' do
      expect(process).to respond_to(:argc)
      expect(process.argc).to be_kind_of(Integer)
      expect(process.argc).to be >= 0
    end

    it 'has an argv member that returns the expected value' do
      expect(process).to respond_to(:argv)
      expect(process.argv).to be_kind_of(Integer)
      expect(process.argv).to be >= 0
    end

    it 'has a envp member that returns the expected value' do
      expect(process).to respond_to(:envp)
      expect(process.envp).to be_kind_of(Integer)
      expect(process.envp).to be >= 0
    end

    it 'has a dmodel member that returns the expected value' do
      expect(process).to respond_to(:dmodel)
      expect(process.dmodel).to be_kind_of(Integer)
      expect(process.dmodel).to be >= 0
    end

    it 'has a taskid member that returns the expected value' do
      expect(process).to respond_to(:taskid)
      expect(process.taskid).to be_kind_of(Integer)
      expect(process.taskid).to be >= 0
    end

    it 'has a projid member that returns the expected value' do
      expect(process).to respond_to(:projid)
      expect(process.projid).to be_kind_of(Integer)
      expect(process.projid).to be >= 0
    end

    it 'has a nzomb member that returns the expected value' do
      expect(process).to respond_to(:nzomb)
      expect(process.nzomb).to be_kind_of(Integer)
      expect(process.nzomb).to be >= 0
    end

    it 'has a poolid member that returns the expected value' do
      expect(process).to respond_to(:poolid)
      expect(process.poolid).to be_kind_of(Integer)
      expect(process.poolid).to be >= 0
    end

    it 'has a zoneid member that returns the expected value' do
      expect(process).to respond_to(:zoneid)
      expect(process.zoneid).to be_kind_of(Integer)
      expect(process.zoneid).to be >= 0
    end

    it 'has a contract member that returns the expected value' do
      expect(process).to respond_to(:contract)
      expect(process.contract).to be_kind_of(Integer)
      expect(process.contract).to be >= 0
    end
  end

  context 'lwpsinfo struct' do
    process { described_class.ps(:pid => Process.pid) }

    it 'has a lwpid member that returns the expected value' do
      expect(process).to respond_to(:lwpid)
      expect(process.lwpid).to be_kind_of(Integer)
      expect(process.lwpid).to be >= 0
    end

    it 'has a wchan member that returns the expected value' do
      expect(process).to respond_to(:wchan)
      expect(process.wchan).to be_kind_of(Integer)
      expect(process.wchan).to be >= 0
    end

    it 'has a stype member that returns the expected value' do
      expect(process).to respond_to(:stype)
      expect(process.stype).to be_kind_of(Integer)
      expect(process.stype).to be >= 0
    end

    it 'has a state member that returns the expected value' do
      expect(process).to respond_to(:state)
      expect(process.state).to be_kind_of(Integer)
      expect(process.state).to be >= 0
    end

    it 'has a sname member that returns the expected value' do
      expect(process).to respond_to(:sname)
      expect(process.sname).to be_kind_of(String)
      expect(%w[S R Z T I O]).to include(process.sname)
    end

    it 'has a nice member that returns the expected value' do
      expect(process).to respond_to(:nice)
      expect(process.nice).to be_kind_of(Integer)
      expect(process.nice).to be >= 0
    end

    it 'has a syscall member that returns the expected value' do
      expect(process).to respond_to(:syscall)
      expect(process.syscall).to be_kind_of(Integer)
      expect(process.syscall).to be >= 0
    end

    it 'has a pri member that returns the expected value' do
      expect(process).to respond_to(:pri)
      expect(process.pri).to be_kind_of(Integer)
      expect(process.pri).to be >= 0
    end

    it 'has a clname member that returns the expected value' do
      expect(process).to respond_to(:clname)
      expect(process.clname).to be_kind_of(String)
      expect(process.clname.size).to be_between(0, 8)
    end

    it 'has a name member that returns the expected value' do
      expect(process).to respond_to(:name)
      expect(process.name).to be_kind_of(String)
      expect(process.name.size).to be_between(0, 16)
    end

    it 'has an onpro member that returns the expected value' do
      expect(process).to respond_to(:onpro)
      expect(process.onpro).to be_kind_of(Integer)
      expect(process.onpro).to be >= 0
    end

    it 'has a bindpro member that returns the expected value' do
      expect(process).to respond_to(:bindpro)
      expect(process.bindpro).to be_kind_of(Integer)
      expect(process.bindpro).to be >= -1
    end

    it 'has a bindpset member that returns the expected value' do
      expect(process).to respond_to(:bindpset)
      expect(process.bindpset).to be_kind_of(Integer)
      expect(process.bindpset).to be >= -1
    end
  end
end
