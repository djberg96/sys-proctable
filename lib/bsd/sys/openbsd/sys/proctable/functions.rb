require 'ffi'

module Sys
  module ProcTableFunctions
    extend FFI::Library
    ffi_lib :kvm

    # attach_function :devname, [:dev_t, :mode_t], :string
    attach_function :kvm_openfiles, [:string, :string, :string, :longint, :string], :pointer
    attach_function :kvm_close, [:pointer], :int
    attach_function :kvm_getprocs, [:pointer, :int, :int, :size_t, :pointer], :pointer
    attach_function :kvm_getargv, [:pointer, :pointer, :int], :pointer
  end
end
