/**********************************************************************
 * Mac OS X code for sys-proctable Ruby library.                      *
 *                                                                    *
 * Date: 3-Mar-2006 (original submission date)                        *
 * Author: David Felstead (david.felstead at gmail dot com)           *
 * Based on bsd.c by Daniel J. Berger (djberg96 at gmail dot com)     *
 *********************************************************************/
#include "ruby.h"
#include <sys/param.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <sys/user.h>
#include <errno.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define pid_of(pproc) pproc->kp_proc.p_pid

#define SYS_PROCTABLE_VERSION "0.9.7"

#define PROC_MIB_LEN 4
#define ARGS_MIB_LEN 3

#ifndef ARGS_MAX_LEN
#define ARGS_MAX_LEN sysconf(_SC_ARG_MAX)
#endif

VALUE cProcTableError, sProcStruct;

int argv_of_pid(int pid, VALUE* v_cmdline, VALUE* v_exe, VALUE* v_environ) {
  int mib[3], argmax, nargs, c = 0;
  size_t size;
  char *procargs, *sp, *np, *cp;
  int show_args = 1;

  mib[0] = CTL_KERN;
  mib[1] = KERN_ARGMAX;

  size = sizeof(argmax);

  if (sysctl(mib, 2, &argmax, &size, NULL, 0) == -1)
    goto ERROR_A;

  // Allocate space for the arguments.
  procargs = (char *)ruby_xmalloc(argmax);

  /*
   * Make a sysctl() call to get the raw argument space of the process.
   * The layout is documented in start.s, which is part of the Csu
   * project.  In summary, it looks like:
   *
   * /---------------\ 0x00000000
   * :               :
   * :               :
   * |---------------|
   * | argc          |
   * |---------------|
   * | arg[0]        |
   * |---------------|
   * :               :
   * :               :
   * |---------------|
   * | arg[argc - 1] |
   * |---------------|
   * | 0             |
   * |---------------|
   * | env[0]        |
   * |---------------|
   * :               :
   * :               :
   * |---------------|
   * | env[n]        |
   * |---------------|
   * | 0             |
   * |---------------| <-- Beginning of data returned by sysctl() is here.
   * | argc          |
   * |---------------|
   * | exec_path     |
   * |:::::::::::::::|
   * |               |
   * | String area.  |
   * |               |
   * |---------------| <-- Top of stack.
   * :               :
   * :               :
   * \---------------/ 0xffffffff
   */
  mib[0] = CTL_KERN;
  mib[1] = KERN_PROCARGS2;
  mib[2] = pid;

  size = (size_t)argmax;

  if (sysctl(mib, 3, procargs, &size, NULL, 0) == -1)
    goto ERROR_B;

  memcpy(&nargs, procargs, sizeof(nargs));
  cp = procargs + sizeof(nargs);

  // Copy exec_path to ruby String.
  *v_exe = rb_str_new2(cp);

  // Skip the saved exec_path.
  for (; cp < &procargs[size]; cp++) {
    if (*cp == '\0')
      break; // End of exec_path reached.
  }

  if (cp == &procargs[size])
    goto ERROR_B;

  // Skip trailing '\0' characters.
  for (; cp < &procargs[size]; cp++){
    if (*cp != '\0')
      break; // Beginning of first argument reached.
  }

  if (cp == &procargs[size])
    goto ERROR_B;

  // Save where the argv[0] string starts.
  sp = cp;

  /*
   * Iterate through the '\0'-terminated strings and convert '\0' to ' '
   * until a string is found that has a '=' character in it (or there are
   * no more strings in procargs).  There is no way to deterministically
   * know where the command arguments end and the environment strings
   * start, which is why the '=' character is searched for as a heuristic.
   */
  for (np = NULL; c < nargs && cp < &procargs[size]; cp++) {
    if (*cp == '\0') {
      c++;

      if (np != NULL)
        *np = ' '; // Convert previous '\0'.

      // Note location of current '\0'.
      np = cp;

      if (!show_args) {
        /*
         * Don't convert '\0' characters to ' '.
         * However, we needed to know that the
         * command name was terminated, which we
         * now know.
         */
        break;
      }
    }
  }

  /*
   * sp points to the beginning of the arguments/environment string, and
   * np should point to the '\0' terminator for the string.
   */
  if (np == NULL || np == sp)
    goto ERROR_B; // Empty or unterminated string.

  // Make a copy of the string to ruby String.
  *v_cmdline = rb_str_new2(sp);

  // Read environment variables to ruby Hash.
  *v_environ = rb_hash_new();

  while (cp[0]) {
    sp = strsep(&cp, "=");

    if (!sp || !cp)
      break;

    rb_hash_aset(*v_environ, rb_str_new2(sp), rb_str_new2(cp));
    cp += strlen(cp) + 1;
  }

  // Cleanup.
  ruby_xfree(procargs);
  return 0;

  ERROR_B:
  free(procargs);
  ERROR_A:
  return -1;
}

/*
 * call-seq:
 *    ProcTable.ps(pid=nil)
 *    ProcTable.ps(pid=nil){ |ps| ... }
 *
 * In block form, yields a ProcTableStruct for each process entry that you
 * have rights to.  This method returns an array of ProcTableStruct's in
 * non-block form.
 *
 * If a +pid+ is provided, then only a single ProcTableStruct is yielded or
 * returned, or nil if no process information is found for that +pid+.
 */
static VALUE pt_ps(int argc, VALUE* argv, VALUE klass){
  int err;
  char state[8];
  struct kinfo_proc* procs;
  VALUE v_pid, v_tty_num, v_tty_dev, v_start_time;
  VALUE v_pstruct = Qnil;
  VALUE v_array = rb_ary_new();
  size_t length, count;
  size_t i = 0;
  int g;
  VALUE v_cmdline, v_exe, v_environ, v_groups;

  // Passed into sysctl call
  static const int name_mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};

  rb_scan_args(argc, argv, "01", &v_pid);

  // Get size of proc kproc buffer
  err = sysctl( (int *) name_mib, PROC_MIB_LEN, NULL, &length, NULL, 0);

  if(err == -1)
    rb_raise(cProcTableError, "sysctl: %s", strerror(errno));

  // Populate the kproc buffer
  procs = ruby_xmalloc(length);

  err = sysctl( (int *) name_mib, PROC_MIB_LEN, procs, &length, NULL, 0);

  if(err == -1)
    rb_raise(cProcTableError, "sysctl: %s", strerror(errno));

  // If we're here, we got our list
  count = length / sizeof(struct kinfo_proc);

  for(i = 0; i < count; i++) {
    v_tty_num = Qnil;
    v_tty_dev = Qnil;
    v_start_time = Qnil;

    // If a PID is provided, skip unless the PID matches
    if( (!NIL_P(v_pid)) && (procs[i].kp_proc.p_pid != NUM2INT(v_pid)) )
      continue;

    // cmdline will be set only if process exists and belongs to current user or
    // current user is root
    v_cmdline = Qnil;
    v_exe = Qnil;
    v_environ = Qnil;
    argv_of_pid(procs[i].kp_proc.p_pid, &v_cmdline, &v_exe, &v_environ);

    // Get the start time of the process
    v_start_time = rb_time_new(
      procs[i].kp_proc.p_un.__p_starttime.tv_sec,
      procs[i].kp_proc.p_un.__p_starttime.tv_usec
    );

    // Get the state of the process
    switch(procs[i].kp_proc.p_stat)
    {
      case SIDL:
        strcpy(state, "idle");
        break;
      case SRUN:
        strcpy(state, "run");
        break;
      case SSLEEP:
        strcpy(state, "sleep");
        break;
      case SSTOP:
        strcpy(state, "stop");
        break;
      case SZOMB:
        strcpy(state, "zombie");
        break;
      default:
        strcpy(state, "unknown");
        break;
    }

    // Get ttynum and ttydev. If ttynum is -1, there is no tty.
    if(procs[i].kp_eproc.e_tdev != -1){
      v_tty_num = INT2FIX(procs[i].kp_eproc.e_tdev),
      v_tty_dev = rb_str_new2(devname(procs[i].kp_eproc.e_tdev, S_IFCHR));
    }

    v_groups = rb_ary_new();
    for (g = 0; g < procs[i].kp_eproc.e_ucred.cr_ngroups; ++g) {
      rb_ary_push(v_groups, INT2FIX(procs[i].kp_eproc.e_ucred.cr_groups[g]));
    }

    v_pstruct = rb_struct_new(
      sProcStruct,
      INT2FIX(procs[i].kp_proc.p_pid),
      INT2FIX(procs[i].kp_eproc.e_ppid),
      INT2FIX(procs[i].kp_eproc.e_pgid),
      INT2FIX(procs[i].kp_eproc.e_pcred.p_ruid),
      INT2FIX(procs[i].kp_eproc.e_pcred.p_rgid),
      INT2FIX(procs[i].kp_eproc.e_ucred.cr_uid),
      rb_ary_entry(v_groups, 0),
      v_groups,
      INT2FIX(procs[i].kp_eproc.e_pcred.p_svuid),
      INT2FIX(procs[i].kp_eproc.e_pcred.p_svgid),
      rb_str_new2(procs[i].kp_proc.p_comm),
      rb_str_new2(state),
      rb_float_new(procs[i].kp_proc.p_pctcpu),
      Qnil,
      v_tty_num,
      v_tty_dev,
      rb_str_new2(procs[i].kp_eproc.e_wmesg),
      INT2FIX(procs[i].kp_proc.p_rtime.tv_sec),
      INT2FIX(procs[i].kp_proc.p_priority),
      INT2FIX(procs[i].kp_proc.p_usrpri),
      INT2FIX(procs[i].kp_proc.p_nice),
      v_cmdline,
      v_exe,
      v_environ,
      v_start_time,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_maxrss) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_ixrss) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_idrss) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_isrss) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_minflt) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_majflt) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_nswap) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_inblock) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_oublock) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_msgsnd) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_msgrcv) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_nsignals) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_nvcsw) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_nivcsw) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_utime.tv_sec) : Qnil,
      (procs[i].kp_proc.p_ru && procs[i].kp_proc.p_stat != 5) ? LONG2NUM(procs[i].kp_proc.p_ru->ru_stime.tv_sec) : Qnil
    );

    OBJ_FREEZE(v_pstruct); // This is read-only data

    if(rb_block_given_p())
      rb_yield(v_pstruct);
    else
      rb_ary_push(v_array, v_pstruct);
  }

  if(procs) free(procs);

  if(!rb_block_given_p()){
    if(NIL_P(v_pid))
      return v_array;
    else
      return v_pstruct;
  }

  return Qnil;
}

/*
 * call-seq:
 *    ProcTable.fields
 *
 * Returns an array of fields that each ProcTableStruct will contain.  This
 * may be useful if you want to know in advance what fields are available
 * without having to perform at least one read of the /proc table.
 */
static VALUE pt_fields(VALUE klass){
  VALUE v_array = rb_ary_new();

  VALUE v_members = rb_struct_s_members(sProcStruct), v_member;
  long size = RARRAY_LEN(v_members);
  int i;

  for(i = 0; i < size; i++) {
    v_member = rb_funcall(rb_ary_entry(v_members, i), rb_intern("to_s"), 0);
    rb_ary_push(v_array, v_member);
  }

  return v_array;
}

/*
 * A Ruby interface for gathering process table information.
 */
void Init_proctable(){
  VALUE mSys, cProcTable;

  /* The Sys module serves as a namespace only */
  mSys = rb_define_module("Sys");

  /* The ProcTable class encapsulates process table information */
  cProcTable = rb_define_class_under(mSys, "ProcTable", rb_cObject);

  /* The Error class typically raised if any of the ProcTable methods fail */
  cProcTableError = rb_define_class_under(cProcTable, "Error", rb_eStandardError);

  /* Singleton methods */

  rb_define_singleton_method(cProcTable, "ps", pt_ps, -1);
  rb_define_singleton_method(cProcTable, "fields", pt_fields, 0);

  /* There is no constructor */
  rb_funcall(cProcTable, rb_intern("private_class_method"), 1, ID2SYM(rb_intern("new")));

  /* Constants */

  /* 0.9.7: The version of the sys-proctable library */
  rb_define_const(cProcTable, "VERSION", rb_str_new2(SYS_PROCTABLE_VERSION));

  /* Structs */

  sProcStruct = rb_struct_define("ProcTableStruct",
    "pid",         /* Process identifier */
    "ppid",        /* Parent process id */
    "pgid",        /* Process group id */
    "ruid",        /* Real user id */
    "rgid",        /* Real group id */
    "euid",        /* Effective user id */
    "egid",        /* Effective group id */
    "groups",      /* All effective group ids */
    "svuid",       /* Saved effective user id */
    "svgid",       /* Saved effective group id */
    "comm",        /* Command name (15 chars) */
    "state",       /* Process status */
    "pctcpu",      /* %cpu for this process during p_swtime */
    "oncpu",       /* nil */
    "tnum",        /* Controlling tty dev */
    "tdev",        /* Controlling tty name */
    "wmesg",       /* Wchan message */
    "rtime",       /* Real time */
    "priority",    /* Process priority */
    "usrpri",      /* User-priority */
    "nice",        /* Process "nice" value */
    "cmdline",     /* Complete command line */
    "exe",         /* Saved pathname of the executed command */
    "environ",     /* Hash with process environment variables */
    "starttime",   /* Process start time */
    "maxrss",      /* Max resident set size (PL) */
    "ixrss",       /* Integral shared memory size (NU) */
    "idrss",       /* Integral unshared data (NU) */
    "isrss",       /* Integral unshared stack (NU) */
    "minflt",      /* Page reclaims (NU) */
    "majflt",      /* Page faults (NU) */
    "nswap",       /* Swaps (NU) */
    "inblock",     /* Block input operations (atomic) */
    "oublock",     /* Block output operations (atomic) */
    "msgsnd",      /* Messages sent (atomic) */
    "msgrcv",      /* Messages received (atomic) */
    "nsignals",    /* Signals received (atomic) */
    "nvcsw",       /* Voluntary context switches (atomic) */
    "nivcsw",      /* Involuntary context switches (atomic) */
    "utime",       /* User time used (PL) */
    "stime",       /* System time used (PL) */
    NULL
  );
}
