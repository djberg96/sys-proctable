require 'ffi'

module Sys
  module ProcTableFunctions
    extend FFI::Library
    ffi_lib :kvm

    attach_function :devname, [:dev_t, :mode_t], :string
    attach_function :kvm_open, [:string, :string, :string, :int, :string], :pointer
    attach_function :kvm_close, [:pointer], :int
    attach_function :kvm_getprocs, [:pointer, :int, :int, :pointer], :pointer
    attach_function :kvm_getargv, [:pointer, :pointer, :int], :pointer
  end
end
