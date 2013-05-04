#ifndef VM_CORE_SUBSET_H
#define VM_CORE_SUBSET_H

/* to avoid warning */
struct rb_thread_struct;
struct rb_control_frame_struct;
typedef int rb_iseq_t;
typedef int rb_method_entry_t;

/* rb_call_info_t contains calling information including inline cache */
typedef struct rb_call_info_struct {
    /* fixed at compile time */
    ID mid;
    VALUE flag;
    int orig_argc;
    rb_iseq_t *blockiseq;

    /* inline cache: keys */
    VALUE vmstat;
    VALUE klass;

    /* inline cache: values */
    const rb_method_entry_t *me;
    VALUE defined_class;

    /* temporary values for method calling */
    int argc;
    struct rb_block_struct *blockptr;
    VALUE recv;
    union {
	int opt_pc; /* used by iseq */
	long index; /* used by ivar */
	int missing_reason; /* used by method_missing */
	int inc_sp; /* used by cfunc */
    } aux;

    VALUE (*call)(struct rb_thread_struct *th, struct rb_control_frame_struct *cfp, struct rb_call_info_struct *ci);
} rb_call_info_t;
typedef rb_call_info_t *CALL_INFO;

#define VM_CALL_ARGS_BLOCKARG   (0x01 << 2) //copy from vm_core.h

#endif /* VM_CORE_SUBSET_H */
