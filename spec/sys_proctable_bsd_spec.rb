################################################################
# sys_proctable_bsd_rspec.rb
#
# Specs for BSD related operating systems for the sys-proctable
# library. You should run these tests via the 'rake spec' task.
################################################################
require 'spec_helper'
require 'mkmf-lite'

RSpec.describe Sys::ProcTable, :bsd do
  let(:fields_freebsd){
    %w[
      pid ppid pgid tpgid sid tsid jobc uid ruid rgid
      ngroups groups size rssize swrss tsize dsize ssize
      xstat acflag pctcpu estcpu slptime swtime runtime start
      flag state nice lock rqindex oncpu lastcpu wmesg login
      lockname comm ttynum ttydev jid priority usrpri cmdline
      utime stime maxrss ixrss idrss isrss minflt majflt nswap
      inblock oublock msgsnd msgrcv nsignals nvcsw nivcsw
    ]
  }

  let(:fields_dragonfly){
    %w[
      paddr flags stat lock acflag traceflag fd siglist sigignore
      sigcatch sigflag start comm uid ngroups groups ruid svuid
      rgid svgid pid ppid pgid jobc sid login tdev tpgid tsid exitstat
      nthreads nice swtime vm_map_size vm_rssize vm_swrss vm_tsize
      vm_dsize vm_ssize vm_prssize jailid ru cru auxflags lwp ktaddr
    ]
  }

  context 'fields singleton method' do
    it 'responds to a fields method' do
      expect(described_class).to respond_to(:fields)
    end

    it 'returns the expected results for the fields method' do
      fields = RbConfig::CONFIG['host_os'] =~ /freebsd/i ? fields_freebsd : fields_dragonfly
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
      expect(process.ppid).to be_kind_of(Integer)
    end

    it 'contains a pgid member and returns the expected value' do
      expect(process).to respond_to(:pgid)
      expect(process.pgid).to be_kind_of(Integer)
    end

    it 'contains a ruid member and returns the expected value' do
      expect(process).to respond_to(:ruid)
      expect(process.ruid).to be_kind_of(Integer)
    end

    it 'contains a rgid member and returns the expected value' do
      expect(process).to respond_to(:rgid)
      expect(process.rgid).to be_kind_of(Integer)
    end

    it 'contains a comm member and returns the expected value' do
      expect(process).to respond_to(:comm)
      expect(process.comm).to be_kind_of(String)
    end

    it 'contains a state member and returns the expected value', :freebsd do
      expect(process).to respond_to(:state)
      expect(process.state).to be_kind_of(String)
    end

    it 'contains a pctcpu member and returns the expected value', :freebsd do
      expect(process).to respond_to(:pctcpu)
      expect(process.pctcpu).to be_kind_of(Float)
    end

    it 'contains a oncpu member and returns the expected value', :freebsd do
      expect(process).to respond_to(:oncpu)
      expect(process.oncpu).to be_kind_of(Integer)
    end

    it 'contains a ttynum member and returns the expected value', :freebsd do
      expect(process).to respond_to(:ttynum)
      expect(process.ttynum).to be_kind_of(Integer)
    end

    it 'contains a ttydev member and returns the expected value', :freebsd do
      expect(process).to respond_to(:ttydev)
      expect(process.ttydev).to be_kind_of(String)
    end

    it 'contains a wmesg member and returns the expected value', :freebsd do
      expect(process).to respond_to(:wmesg)
      expect(process.wmesg).to be_kind_of(String)
    end

    it 'contains a runtime member and returns the expected value', :freebsd do
      expect(process).to respond_to(:runtime)
      expect(process.runtime).to be_kind_of(Integer)
    end

    it 'contains a priority member and returns the expected value', :freebsd do
      expect(process).to respond_to(:priority)
      expect(process.priority).to be_kind_of(Integer)
    end

    it 'contains a usrpri member and returns the expected value', :freebsd do
      expect(process).to respond_to(:usrpri)
      expect(process.usrpri).to be_kind_of(Integer)
    end

    it 'contains a nice member and returns the expected value' do
      expect(process).to respond_to(:nice)
      expect(process.nice).to be_kind_of(Integer)
    end

    it 'contains a cmdline member and returns the expected value' do
      expect(process).to respond_to(:cmdline)
      expect(process.cmdline).to be_kind_of(String)
    end

    it 'contains a start member and returns the expected value' do
      expect(process).to respond_to(:start)
      expect(process.start).to be_kind_of(Time)
    end

    it 'contains a maxrss member and returns the expected value', :freebsd do
      expect(process).to respond_to(:maxrss)
      expect(process.maxrss).to be_kind_of(Integer)
    end

    it 'contains a ixrss member and returns the expected value', :freebsd do
      expect(process).to respond_to(:ixrss)
      expect(process.ixrss).to be_kind_of(Integer)
    end

    # TODO: The value returned on PC BSD 10 does not appear to be valid. Investigate.
    it 'contains a idrss member and returns the expected value', :freebsd do
      expect(process).to respond_to(:idrss)
      expect(process.idrss).to be_kind_of(Numeric)
    end

    it 'contains a isrss member and returns the expected value', :freebsd do
      expect(process).to respond_to(:isrss)
      expect(process.isrss).to be_kind_of(Integer)
    end

    it 'contains a minflt member and returns the expected value', :freebsd do
      expect(process).to respond_to(:minflt)
      expect(process.minflt).to be_kind_of(Integer)
    end

    it 'contains a majflt member and returns the expected value', :freebsd do
      expect(process).to respond_to(:majflt)
      expect(process.majflt).to be_kind_of(Integer)
    end

    it 'contains a nswap member and returns the expected value', :freebsd do
      expect(process).to respond_to(:nswap)
      expect(process.nswap).to be_kind_of(Integer)
    end

    it 'contains a inblock member and returns the expected value', :freebsd do
      expect(process).to respond_to(:inblock)
      expect(process.inblock).to be_kind_of(Integer)
    end

    it 'contains a oublock member and returns the expected value', :freebsd do
      expect(process).to respond_to(:oublock)
      expect(process.oublock).to be_kind_of(Integer)
    end

    it 'contains a msgsnd member and returns the expected value', :freebsd do
      expect(process).to respond_to(:msgsnd)
      expect(process.msgsnd).to be_kind_of(Integer)
    end

    it 'contains a msgrcv member and returns the expected value', :freebsd do
      expect(process).to respond_to(:msgrcv)
      expect(process.msgrcv).to be_kind_of(Integer)
    end

    it 'contains a nsignals member and returns the expected value', :freebsd do
      expect(process).to respond_to(:nsignals)
      expect(process.nsignals).to be_kind_of(Integer)
    end

    it 'contains a nvcsw member and returns the expected value', :freebsd do
      expect(process).to respond_to(:nvcsw)
      expect(process.nvcsw).to be_kind_of(Integer)
    end

    it 'contains a nivcsw member and returns the expected value', :freebsd do
      expect(process).to respond_to(:nivcsw)
      expect(process.nivcsw).to be_kind_of(Integer)
    end

    it 'contains a utime member and returns the expected value', :freebsd do
      expect(process).to respond_to(:utime)
      expect(process.utime).to be_kind_of(Integer)
    end

    it 'contains a stime member and returns the expected value', :freebsd do
      expect(process).to respond_to(:stime)
      expect(process.stime).to be_kind_of(Integer)
    end
  end

  context 'C struct verification' do
    let(:dummy){ Class.new{ extend Mkmf::Lite } }

    it 'has a timeval struct of the expected size' do
      expect(Sys::ProcTableStructs::Timeval.size).to eq(dummy.check_sizeof('struct timeval', 'sys/time.h'))
    end

    it 'has an rtprio struct of the expected size' do
      expect(Sys::ProcTableStructs::RTPrio.size).to eq(dummy.check_sizeof('struct rtprio', 'sys/rtprio.h'))
    end

    it 'has an rusage struct of the expected size' do
      expect(Sys::ProcTableStructs::Rusage.size).to eq(dummy.check_sizeof('struct rusage', 'sys/resource.h'))
    end

    it 'has an kinfo_lwp struct of the expected size' do
      expect(Sys::ProcTableStructs::KInfoLWP.size).to eq(dummy.check_sizeof('struct kinfo_lwp', 'sys/kinfo.h'))
    end

    it 'has an kinfo_proc struct of the expected size' do
      expect(Sys::ProcTableStructs::KInfoProc.size).to eq(dummy.check_sizeof('struct kinfo_proc', 'sys/kinfo.h'))
    end
  end
end
