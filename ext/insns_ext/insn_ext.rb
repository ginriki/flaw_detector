require File.join(File.dirname(__FILE__),'insns_ext')
module InsnExt
  def insn_num(insn_name)
    return RubyVM::INSTRUCTION_NAMES.index(insn_name.to_s)
  end

  # @todo refactoring from c-function to pure ruby function
  alias :_insn_stack_increase :insn_stack_increase

  if RUBY_VERSION =~ /^2.0/
    VM_CALL_ARGS_BLOCKARG = (0x01 ** 2)

    # Override for substitution of CALL_INFO cast 
    # in c-function@insns_info.inc
    def insn_stack_increase(opcode_index, ary)
      call_info = [:send, :invokesuper, :opt_send_simple, :invokeblock]
      name = RubyVM::INSTRUCTION_NAMES[opcode_index].to_sym
      unless call_info.include?(name)
        return _insn_stack_increase(opcode_index, ary)
      else
        case name
        when :opt_send_simple
          inc = -ary[0][:orig_argc]
        when :invokeblock
          inc = 1-ary[0][:orig_argc]
        when :send, :invokesuper
          inc = -ary[0][:orig_argc]
          inc += -1 if (ary[0][:flag] & VM_CALL_ARGS_BLOCKARG) != 0
        else
          raise "unknown state"
        end
        return inc
      end
    end
  else
    #don't need to override insn_stack_increase
  end
  module_function :insn_num, :insn_stack_increase, :_insn_stack_increase
end
