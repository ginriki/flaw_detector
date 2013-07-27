require 'spec_helper'
require 'insns'

describe InsnsInfo do
  it "InsnsInfo::insn_num equals InsnExt::insn_num" do
    RubyVM::INSTRUCTION_NAMES.each do |name|
      InsnsInfo::insn_num(name).should == InsnExt::insn_num(name)
    end
  end

  it "InsnsInfo::insn_ret_num equals InsnExt::insn_ret_num" do
    RubyVM::INSTRUCTION_NAMES.each do |name|
      InsnsInfo::insn_ret_num(InsnsInfo::insn_num(name)).should == InsnExt::insn_ret_num(InsnExt::insn_num(name))
    end
  end

  it "InsnsInfo::insn_stack_increase equals InsnExt::insn_stack_increase" do
    ary = [1,1]
    RubyVM::INSTRUCTION_NAMES.each do |name|
      case name
      when  "expandarray"
        ary1 = [0,0]
        ary2 = [0,1]
        InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary1).should == InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary1)
        InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary2).should == InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary2)
        InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary1).should_not == InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary2)
      when  "send"
        case RUBY_VERSION[0..2]
        when /^1.9/  
          ary1 = [0,0,0,0]
          ary2 = [0,0,0,4]
        when /^2.0/
          ary1 = [{:orig_argc => 1, :flag => 1}]
          ary2 = [{:orig_argc => 1, :flag => 4}]
        end
        InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary1).should == InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary1)
        InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary2).should == InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary2)
        InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary1).should_not == InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary2)
      when "invokesuper"
        case RUBY_VERSION[0..2]
        when /^1.9/
          ary1 = [0,0,0,0]
          ary2 = [0,0,4,0]
        when /^2.0/
          ary1 = [{:orig_argc => 1, :flag => 1}]
          ary2 = [{:orig_argc => 1, :flag => 4}]
        end
        InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary1).should == InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary1)
        InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary2).should == InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary2)
        InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary1).should_not == InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary2)
      when "opt_send_simple"
        ary_opt = [{:orig_argc => 1}]
        InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary_opt).should == InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary_opt)
      when "invokeblock"
        ary_inv = [{:orig_argc => 1}]
        InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary_inv).should == InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary_inv)
      else
        InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary).should == InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary)
      end
    end
  end
end 
