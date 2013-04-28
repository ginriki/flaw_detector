require File.join(File.dirname(__FILE__),'insns_ext')
module InsnExt
  def insn_num(insn_name)
    return RubyVM::INSTRUCTION_NAMES.index(insn_name.to_s)
  end
  module_function :insn_num
end
