# frozen_string_literal: true

############################################################################
# sys_proctable_windows_spec.rb
#
# Test suite for the sys-proctable library for MS Windows. This should be
# run via the 'rake spec' task.
############################################################################
require 'spec_helper'
require 'socket'

RSpec.describe Sys::ProcTable, :windows do
  let(:hostname) { Socket.gethostname }
  let(:fields) {
    %w[
        caption
        cmdline
        comm
        creation_class_name
        creation_date
        cs_creation_class_name
        cs_name description
        executable_path
        execution_state
        handle
        handle_count
        install_date
        kernel_mode_time
        maximum_working_set_size
        minimum_working_set_size name
        os_creation_class_name
        os_name
        other_operation_count
        other_transfer_count
        page_faults
        page_file_usage
        ppid
        peak_page_file_usage
        peak_virtual_size
        peak_working_set_size
        priority
        private_page_count
        pid
        quota_non_paged_pool_usage
        quota_paged_pool_usage
        quota_peak_non_paged_pool_usage
        quota_peak_paged_pool_usage
        read_operation_count
        read_transfer_count
        session_id
        status
        termination_date
        thread_count
        user_mode_time
        virtual_size
        windows_version
        working_set_size
        write_operation_count
        write_transfer_count
     ]
  }

  context 'fields' do
    it 'responds to a fields method' do
      expect(described_class).to respond_to(:fields)
    end

    it 'returns the expected results for the fields method' do
      expect(described_class.fields).to be_kind_of(Array)
      expect(described_class.fields).to eql(fields)
    end
  end

  context 'ps' do
    it 'accepts an optional host' do
      expect{ described_class.ps(:host => hostname) }.not_to raise_error
    end

    it 'ignores unused options' do
      expect{ described_class.ps(:smaps => false) }.not_to raise_error
    end
  end

  context 'ProcTable::Struct members' do
    subject(:process){ described_class.ps.first }

    it 'has a write_transfer_count struct member with the expected data type' do
      expect(process).to respond_to(:write_transfer_count)
      expect(process.write_transfer_count).to be_kind_of(Integer)
    end

    it 'has a write_operation_count struct member with the expected data type' do
      expect(process).to respond_to(:write_operation_count)
      expect(process.write_operation_count).to be_kind_of(Integer)
    end

    it 'has a working_set_size struct member with the expected data type' do
      expect(process).to respond_to(:working_set_size)
      expect(process.working_set_size).to be_kind_of(Integer)
    end

    it 'has a windows_version struct member with the expected data type' do
      expect(process).to respond_to(:windows_version)
      expect(process.windows_version).to be_kind_of(String)
    end

    it 'has a virtual_size struct member with the expected data type' do
      expect(process).to respond_to(:virtual_size)
      expect(process.virtual_size).to be_kind_of(Integer)
    end

    it 'has a user_mode_time struct member with the expected data type' do
      expect(process).to respond_to(:user_mode_time)
      expect(process.user_mode_time).to be_kind_of(Integer)
    end

    it 'has a thread_count struct member with the expected data type' do
      expect(process).to respond_to(:thread_count)
      expect(process.thread_count).to be_kind_of(Integer)
    end

    it 'has a termination_date struct member with the expected data type' do
      expect(process).to respond_to(:termination_date)
      expect(process.termination_date).to be_kind_of(Date) if process.termination_date
    end

    it 'has a status struct member with the expected data type' do
      expect(process).to respond_to(:status)
      expect(process.status).to be_nil # Always nil according to MSDN
    end

    it 'has a session_id struct member with the expected data type' do
      expect(process).to respond_to(:session_id)
      expect(process.session_id).to be_kind_of(Integer)
    end

    it 'has a read_transfer_count struct member with the expected data type' do
      expect(process).to respond_to(:read_transfer_count)
      expect(process.read_transfer_count).to be_kind_of(Integer)
    end

    it 'has a read_operation_count struct member with the expected data type' do
      expect(process).to respond_to(:read_operation_count)
      expect(process.read_operation_count).to be_kind_of(Integer)
    end

    it 'has a quota_peak_paged_pool_usage struct member with the expected data type' do
      expect(process).to respond_to(:quota_peak_paged_pool_usage)
      expect(process.quota_peak_paged_pool_usage).to be_kind_of(Integer)
    end

    it 'has a quota_peak_non_paged_pool_usage struct member with the expected data type' do
      expect(process).to respond_to(:quota_peak_non_paged_pool_usage)
      expect(process.quota_peak_non_paged_pool_usage).to be_kind_of(Integer)
    end

    it 'has a quota_paged_pool_usage struct member with the expected data type' do
      expect(process).to respond_to(:quota_paged_pool_usage)
      expect(process.quota_paged_pool_usage).to be_kind_of(Integer)
    end

    it 'has a quota_non_paged_pool_usage struct member with the expected data type' do
      expect(process).to respond_to(:quota_non_paged_pool_usage)
      expect(process.quota_non_paged_pool_usage).to be_kind_of(Integer)
    end

    it 'has a pid struct member with the expected data type' do
      expect(process).to respond_to(:pid)
      expect(process.pid).to be_kind_of(Integer)
    end

    it 'has a private_page_count struct member with the expected data type' do
      expect(process).to respond_to(:private_page_count)
      expect(process.private_page_count).to be_kind_of(Integer)
    end

    it 'has a priority struct member with the expected data type' do
      expect(process).to respond_to(:priority)
      expect(process.priority).to be_kind_of(Integer)
    end

    it 'has a peak_working_set_size struct member with the expected data type' do
      expect(process).to respond_to(:peak_working_set_size)
      expect(process.peak_working_set_size).to be_kind_of(Integer)
    end

    it 'has a peak_virtual_size struct member with the expected data type' do
      expect(process).to respond_to(:peak_virtual_size)
      expect(process.peak_virtual_size).to be_kind_of(Integer)
    end

    it 'has a peak_page_file_usage struct member with the expected data type' do
      expect(process).to respond_to(:peak_page_file_usage)
      expect(process.peak_page_file_usage).to be_kind_of(Integer)
    end

    it 'has a ppid struct member with the expected data type' do
      expect(process).to respond_to(:ppid)
      expect(process.ppid).to be_kind_of(Integer)
    end

    it 'has a page_file_usage struct member with the expected data type' do
      expect(process).to respond_to(:page_file_usage)
      expect(process.page_file_usage).to be_kind_of(Integer)
    end

    it 'has a page_faults struct member with the expected data type' do
      expect(process).to respond_to(:page_faults)
      expect(process.page_faults).to be_kind_of(Integer)
    end

    it 'has a other_transfer_count struct member with the expected data type' do
      expect(process).to respond_to(:other_transfer_count)
      expect(process.other_transfer_count).to be_kind_of(Integer)
    end

    it 'has a other_operation_count struct member with the expected data type' do
      expect(process).to respond_to(:other_operation_count)
      expect(process.other_operation_count).to be_kind_of(Integer)
    end

    it 'has a os_name struct member with the expected data type' do
      expect(process).to respond_to(:os_name)
      expect(process.os_name).to be_kind_of(String)
    end

    it 'has a os_creation_class_name struct member with the expected data type' do
      expect(process).to respond_to(:os_creation_class_name)
      expect(process.os_creation_class_name).to be_kind_of(String)
    end

    it 'has a name struct member with the expected data type' do
      expect(process).to respond_to(:name)
      expect(process.name).to be_kind_of(String)
    end

    it 'has a minimum_working_set_size struct member with the expected data type' do
      expect(process).to respond_to(:minimum_working_set_size)
      expect(process.minimum_working_set_size).to be_kind_of(Integer) if process.minimum_working_set_size
    end

    it 'has a maximum_working_set_size struct member with the expected data type' do
      expect(process).to respond_to(:maximum_working_set_size)
      expect(process.maximum_working_set_size).to be_kind_of(Integer) if process.maximum_working_set_size
    end

    it 'has a kernel_mode_time struct member with the expected data type' do
      expect(process).to respond_to(:kernel_mode_time)
      expect(process.kernel_mode_time).to be_kind_of(Integer)
    end

    it 'has a install_date struct member with the expected data type' do
      expect(process).to respond_to(:install_date)
      expect(process.install_date).to be_kind_of(Date) if process.install_date
    end

    it 'has a handle_count struct member with the expected data type' do
      expect(process).to respond_to(:handle_count)
      expect(process.handle_count).to be_kind_of(Integer)
    end

    it 'has a handle struct member with the expected data type' do
      expect(process).to respond_to(:handle)
      expect(process.handle).to be_kind_of(String)
    end

    it 'has a execution_state struct member with the expected data type' do
      expect(process).to respond_to(:execution_state)
      expect(process.execution_state).to be_nil
    end

    it 'has a executable_path struct member with the expected data type' do
      expect(process).to respond_to(:executable_path)
      expect(process.executable_path).to be_kind_of(String) if process.executable_path
    end

    it 'has a description struct member with the expected data type' do
      expect(process).to respond_to(:description)
      expect(process.description).to be_kind_of(String)
    end

    it 'has a cs_name struct member with the expected data type' do
      expect(process).to respond_to(:cs_name)
      expect(process.cs_name).to be_kind_of(String)
    end

    it 'has a cs_creation_class_name struct member with the expected data type' do
      expect(process).to respond_to(:cs_creation_class_name)
      expect(process.cs_creation_class_name).to be_kind_of(String)
    end

    it 'has a creation_date struct member with the expected data type' do
      expect(process).to respond_to(:creation_date)
      expect(process.creation_date).to be_kind_of(Date) if process.creation_date
    end

    it 'has a creation_class_name struct member with the expected data type' do
      expect(process).to respond_to(:creation_class_name)
      expect(process.creation_class_name).to be_kind_of(String)
    end

    it 'has a comm struct member with the expected data type' do
      expect(process).to respond_to(:comm)
      expect(process.comm).to be_kind_of(String)
    end

    it 'has a cmdline struct member with the expected data type' do
      expect(process).to respond_to(:cmdline)
      expect(process.cmdline).to be_kind_of(String) if process.cmdline
    end

    it 'has a caption struct member with the expected data type' do
      expect(process).to respond_to(:caption)
      expect(process.caption).to be_kind_of(String)
    end
  end
end
