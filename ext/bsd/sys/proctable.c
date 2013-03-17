/**********************************************************************
 * proctable.c
 *
 * This is a generic kvm interface used by the various BSD flavors
 * for the sys-proctable library.
 **********************************************************************/
#include "ruby.h"
#include <kvm.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <sys/user.h>

#define SYS_PROCTABLE_VERSION "0.9.3"

VALUE cProcTableError, sProcStruct;

const char* fields[] = {
  "pid", "ppid", "pgid", "ruid",
  "rgid", "comm", "state", "pctcpu", "oncpu", "ttynum", "ttydev", "wmesg",
  "time", "priority", "usrpri", "nice", "cmdline", "start",
  "maxrss", "ixrss", "idrss", "isrss", "minflt", "majflt", "nswap",
  "inblock", "oublock", "msgsnd", "msgrcv", "nsignals", "nvcsw", "nivcsw",
  "utime", "stime"
};

/*
 * call-seq:
 *   ProcTable.ps(pid=nil)
 *   ProcTable.ps(pid=nil){ |ps| ... }
 *
 * In block form, yields a ProcTableStruct for each process entry that you
 * have rights to.  This method returns an array of ProcTableStruct's in
 * non-block form.
 *
 * If a +pid+ is provided, then only a single ProcTableStruct is yielded or
 * returned, or nil if no process information is found for that +pid+.
 */
static VALUE pt_ps(int argc, VALUE* argv, VALUE klass){
  kvm_t *kd;
  char errbuf[_POSIX2_LINE_MAX];
  char cmdline[_POSIX_ARG_MAX+1];
  char state[8];
  char** args = malloc(sizeof(char*));
  struct kinfo_proc* procs;
  int count;                     // Holds total number of processes
  int i = 0;
  VALUE v_pid, v_tty_num, v_tty_dev, v_start_time;
  VALUE v_pstruct = Qnil;
  VALUE v_array = Qnil;

  rb_scan_args(argc, argv, "01", &v_pid);

  if(!NIL_P(v_pid))
    Check_Type(v_pid, T_FIXNUM);

  if(!rb_block_given_p())
    v_array = rb_ary_new();

  // Open the kvm interface, get a descriptor
  if((kd = kvm_open(NULL, NULL, NULL, 0, "kvm_open")) == NULL)
    rb_raise(cProcTableError, "kvm_open failed: %s", strerror(errno)); 

  // Get the list of processes
  if((procs = kvm_getprocs(kd, KERN_PROC_ALL, 0, &count)) == NULL) {
    strcpy(errbuf, kvm_geterr(kd));
    kvm_close(kd);
    rb_raise(cProcTableError, errbuf);
  }

  for(i=0; i<count; i++){
    // Reset some variables
    v_tty_num = Qnil;
    v_tty_dev = Qnil;
    v_start_time = Qnil;

    // If a PID is provided, skip unless the PID matches
    if(!NIL_P(v_pid)){
#ifdef HAVE_ST_KP_PROC
      if(procs[i].kp_proc.p_pid != NUM2INT(v_pid))
        continue;
#else
      if(procs[i].ki_pid != NUM2INT(v_pid))
        continue;
#endif
      }

    // Get the command line arguments for the process
    cmdline[0] = '\0';
    args = kvm_getargv(kd, (const struct kinfo_proc *)&procs[i], 0);

    if(args){
      int j = 0;
      while (args[j] && strlen(cmdline) <= _POSIX_ARG_MAX) {
        strcat(cmdline, args[j]);
        strcat(cmdline, " ");
        j++;
       }
    }

    // Get the start time of the process
    v_start_time = rb_time_new(
#ifdef HAVE_ST_E_STATS
      procs[i].kp_eproc.e_stats.p_start.tv_sec,
      procs[i].kp_eproc.e_stats.p_start.tv_usec
#else
      0,0
#endif
    );

    // Get the state of the process
#ifdef HAVE_ST_KP_PROC
    switch(procs[i].kp_proc.p_stat)
#else
    switch(procs[i].ki_stat)
#endif
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

    // Get ttynum and ttydev. If ttynum is -1, there is no tty
#ifdef HAVE_ST_KP_EPROC
    v_tty_num = INT2FIX(procs[i].kp_eproc.e_tdev),
    v_tty_dev = rb_str_new2(devname(procs[i].kp_eproc.e_tdev, S_IFCHR));
#elif HAVE_ST_U_KPROC
    v_tty_num = INT2FIX(procs[i].u_kproc.ki_tdev),
    v_tty_dev = rb_str_new2(devname(procs[i].u_kproc.ki_tdev, S_IFCHR));
#else
    v_tty_num = INT2FIX(procs[i].ki_tdev),
    v_tty_dev = rb_str_new2(devname(procs[i].ki_tdev, S_IFCHR));
#endif

#ifdef HAVE_ST_KP_PROC
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
#ifdef HAVE_ST_P_ONCPU
      INT2FIX(procs[i].kp_proc.p_oncpu),
#else
      Qnil,
#endif
      v_tty_num,
      v_tty_dev,
      rb_str_new2(procs[i].kp_eproc.e_wmesg),
#ifdef HAVE_ST_P_RUNTIME
      INT2FIX(procs[i].kp_proc.p_runtime/1000000),
#else
      Qnil,
#endif
      INT2FIX(procs[i].kp_proc.p_priority),
      INT2FIX(procs[i].kp_proc.p_usrpri),
      INT2FIX(procs[i].kp_proc.p_nice),
      rb_str_new2(cmdline),
      v_start_time,
#ifdef HAVE_ST_E_STATS
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_maxrss),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_ixrss),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_idrss),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_isrss),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_minflt),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_majflt),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_nswap),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_inblock),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_oublock),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_msgsnd),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_msgrcv),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_nsignals),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_nvcsw),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_nivcsw),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_utime.tv_sec),
      LONG2NUM(procs[i].kp_eproc.e_stats.p_ru.ru_stime.tv_sec)
#else
      Qnil, Qnil, Qnil, Qnil, Qnil, Qnil, Qnil, Qnil,
      Qnil, Qnil, Qnil, Qnil, Qnil, Qnil, Qnil, Qnil
#endif
    );
#else
    v_pstruct = rb_struct_new(
      sProcStruct,
      INT2FIX(procs[i].ki_pid),
      INT2FIX(procs[i].ki_ppid),
      INT2FIX(procs[i].ki_pgid),
      INT2FIX(procs[i].ki_ruid),
      INT2FIX(procs[i].ki_rgid),
      rb_str_new2(procs[i].ki_ocomm),
      rb_str_new2(state),
      rb_float_new(procs[i].ki_pctcpu),
      INT2FIX(procs[i].ki_oncpu),
      v_tty_num,
      v_tty_dev,
      rb_str_new2(procs[i].ki_wmesg),
      INT2FIX(procs[i].ki_runtime/1000000),
      INT2FIX(procs[i].ki_pri.pri_level),
      INT2FIX(procs[i].ki_pri.pri_user),
      INT2FIX(procs[i].ki_nice),
      rb_str_new2(cmdline),
      v_start_time,
      Qnil, Qnil, Qnil, Qnil, Qnil, Qnil, Qnil, Qnil,
      Qnil, Qnil, Qnil, Qnil, Qnil, Qnil, Qnil, Qnil
    );
#endif

    OBJ_FREEZE(v_pstruct); // Read-only data

    if(rb_block_given_p())
      rb_yield(v_pstruct);
    else
      rb_ary_push(v_array, v_pstruct);
  }

  if(kd)
    kvm_close(kd);

  if(!NIL_P(v_pid))
    return v_pstruct;

  return v_array; // Nil if block given
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

   /* The error typically raised if any of the ProcTable methods fail */
   cProcTableError = rb_define_class_under(cProcTable, "Error", rb_eStandardError);

   /* Singleton Methods */

   rb_define_singleton_method(cProcTable, "ps", pt_ps, -1);
   rb_define_singleton_method(cProcTable, "fields", pt_fields, 0);

   /* There is no constructor */
   rb_funcall(cProcTable, rb_intern("private_class_method"), 1, ID2SYM(rb_intern("new")));

   /* Constants */

   /* 0.9.3: The version of the sys-proctable library */
   rb_define_const(cProcTable, "VERSION", rb_str_new2(SYS_PROCTABLE_VERSION));

   /* Structures */

   sProcStruct = rb_struct_define("ProcTableStruct","pid","ppid","pgid","ruid",
      "rgid","comm","state","pctcpu","oncpu","ttynum","ttydev","wmesg",
      "time", "priority","usrpri","nice","cmdline","start",
      "maxrss","ixrss","idrss","isrss","minflt","majflt","nswap",
      "inblock","oublock","msgsnd","msgrcv","nsignals","nvcsw","nivcsw",
      "utime","stime", NULL
   );
}
