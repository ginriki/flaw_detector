#define USE_INSN_STACK_INCREASE
#define USE_INSN_RET_NUM
#include "ruby.h"

#define VM_CALL_ARGS_BLOCKARG_BIT  (0x01 << 2)  //copy from vm_core.h
#include "insns.inc"
#include "insns_info.inc"

VALUE wrap_insn_len(VALUE self, VALUE insn)
{
  int len = insn_len(FIX2INT(insn));
  return INT2FIX(len);
}

VALUE wrap_insn_stack_increase(VALUE self, VALUE insn, VALUE ope_ary)
{
  int inc = insn_stack_increase(0, FIX2INT(insn), RARRAY_PTR(ope_ary));
  return INT2FIX(inc);
}

VALUE wrap_insn_ret_num(VALUE self, VALUE insn)
{
  int ret_num = insn_ret_num(FIX2INT(insn));
  return INT2FIX(ret_num);
}

void Init_insns_ext()
{
  VALUE module;
  
  module = rb_define_module("InsnExt");
  rb_define_module_function(module, "insn_len", wrap_insn_len, 1);
  rb_define_module_function(module, "insn_stack_increase", wrap_insn_stack_increase, 2);
  rb_define_module_function(module, "insn_ret_num", wrap_insn_ret_num, 1);
}

