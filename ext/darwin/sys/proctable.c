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
#define pid_of(pproc) pproc->kp_proc.p_pid

#define SYS_PROCTABLE_VERSION "0.9.2"

#define PROC_MIB_LEN 4
#define ARGS_MIB_LEN 3
#define ARGS_MAX_LEN 4096
VALUE cProcTableError, sProcStruct;

const char* fields[] = {
   "pid", "ppid", "pgid", "ruid", "rgid", "comm", "state", "pctcpu", "oncpu",
   "tnum", "tdev", "wmesg", "rtime", "priority", "usrpri", "nice", "cmdline",
   "starttime", "maxrss", "ixrss", "idrss", "isrss", "minflt", "majflt",
   "nswap", "inblock", "oublock", "msgsnd", "msgrcv", "nsignals", "nvcsw",
   "nivcsw", "utime", "stime"
};

int argv_of_pid(int pid, char* cmdline) {
  int    mib[3], argmax, nargs, c = 0;
  size_t    size;
  char    *procargs, *sp, *np, *cp;
  int show_args = 1;

  /* fprintf(stderr, "Getting argv of PID %d\n", pid); */

  mib[0] = CTL_KERN;
  mib[1] = KERN_ARGMAX;

  size = sizeof(argmax);
  if (sysctl(mib, 2, &argmax, &size, NULL, 0) == -1) {
    goto ERROR_A;
  }

  /* Allocate space for the arguments. */
  procargs = (char *)malloc(argmax);
  if (procargs == NULL) {
    goto ERROR_A;
  }


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
  if (sysctl(mib, 3, procargs, &size, NULL, 0) == -1) {
    goto ERROR_B;
  }

  memcpy(&nargs, procargs, sizeof(nargs));
  cp = procargs + sizeof(nargs);

  /* Skip the saved exec_path. */
  for (; cp < &procargs[size]; cp++) {
    if (*cp == '\0') {
      /* End of exec_path reached. */
      break;
    }
  }
  if (cp == &procargs[size]) {
    goto ERROR_B;
  }

  /* Skip trailing '\0' characters. */
  for (; cp < &procargs[size]; cp++) {
    if (*cp != '\0') {
      /* Beginning of first argument reached. */
      break;
    }
  }
  if (cp == &procargs[size]) {
    goto ERROR_B;
  }
  /* Save where the argv[0] string starts. */
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
      if (np != NULL) {
          /* Convert previous '\0'. */
          *np = ' ';
      } else {
          /* *argv0len = cp - sp; */
      }
      /* Note location of current '\0'. */
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
  if (np == NULL || np == sp) {
    /* Empty or unterminated string. */
    goto ERROR_B;
  }

  /* Make a copy of the string. */
  strcpy(cmdline, sp);

  /* Clean up. */
  free(procargs);
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
   char args[ARGS_MAX_LEN+1];

   // Passed into sysctl call
   static const int name_mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};

   rb_scan_args(argc, argv, "01", &v_pid);

   // Get size of proc kproc buffer
   err = sysctl( (int *) name_mib, PROC_MIB_LEN, NULL, &length, NULL, 0);

   if(err == -1)
      rb_raise(cProcTableError, "sysctl: %s", strerror(errno));

   // Populate the kproc buffer
   procs = malloc(length);

   if(procs == NULL)
      rb_raise(cProcTableError, "malloc: %s", strerror(errno));

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

      *args = '\0';

      /* Query the command line args */
      /* TODO: Cmd line not working for now - fix */

      /*args_mib[ARGS_MIB_LEN - 1] = procs[i].kp_proc.p_pid;
      args_err = sysctl( (int *) args_mib, ARGS_MIB_LEN, args, &args_size, NULL, 0);

      if(args_err >= 0) {
         fprintf(stderr, "Ret: %d LEN: %d\n", err, args_size);
         char *c;
         for(c = args; c < args+args_size; c++)
            if(*c == '\0') *c = ' ';
         args[args_size] = '\0';
      } else {
         fprintf(stderr, "err: %s LEN: %d\n", strerror(errno), args_size);
      }*/
      char cmdline[ARGS_MAX_LEN+1];

      argv_of_pid(procs[i].kp_proc.p_pid, &cmdline);
      /* free(cmdline); */

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

      v_pstruct = rb_struct_new(
         sProcStruct,
         INT2FIX(procs[i].kp_proc.p_pid),
         INT2FIX(procs[i].kp_eproc.e_ppid),
         INT2FIX(procs[i].kp_eproc.e_pgid),
         INT2FIX(procs[i].kp_eproc.e_pcred.p_ruid),
         INT2FIX(procs[i].kp_eproc.e_pcred.p_rgid),
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
         rb_str_new2(cmdline),
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
   int size = sizeof(fields) / sizeof(fields[0]);
   int i;

   for(i = 0; i < size; i++)
      rb_ary_push(v_array, rb_str_new2(fields[i]));

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

   /* 0.9.1: The version of the sys-proctable library */
   rb_define_const(cProcTable, "VERSION", rb_str_new2(SYS_PROCTABLE_VERSION));

   /* Structs */

   sProcStruct = rb_struct_define("ProcTableStruct","pid","ppid","pgid","ruid",
      "rgid","comm","state","pctcpu","oncpu","tnum","tdev","wmesg",
      "rtime", "priority","usrpri","nice","cmdline","starttime",
      "maxrss","ixrss","idrss","isrss","minflt","majflt","nswap",
      "inblock","oublock","msgsnd","msgrcv","nsignals","nvcsw","nivcsw",
      "utime","stime", NULL
   );
}

