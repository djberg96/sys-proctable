require 'mkmf'

have_type('rb_pid_t', 'ruby.h')

have_library('kvm')
have_func('kvm_openfiles')
have_struct_member('struct kinfo_proc', 'kp_proc', 'sys/user.h')
have_struct_member('struct kinfo_proc', 'kp_eproc', 'sys/user.h')
have_struct_member('struct kinfo_proc', 'u_kproc', 'sys/user.h')
have_struct_member('struct eproc', 'e_stats', 'sys/sysctl.h')
have_struct_member('struct eproc', 'p_oncpu', 'sys/sysctl.h')
have_struct_member('struct eproc', 'p_runtime', 'sys/sysctl.h')          

create_makefile('sys/proctable', 'sys')
