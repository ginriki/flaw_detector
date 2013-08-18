require 'spec_helper'
require 'flaw_detector/insns/insns'

include FlawDetector

describe FlawDetector::InsnsInfo do
  RubyVM::INSTRUCTION_NAMES.each do |name|
    describe "::insn_num :#{name}" do
      it{expect(InsnsInfo::insn_num(name)).to eq(InsnExt::insn_num(name))}
    end
  end


    RubyVM::INSTRUCTION_NAMES.each do |name|
    describe "::insn_ret_num #{InsnsInfo::insn_num(name)}(=#{name})" do
      it{expect(InsnsInfo::insn_ret_num(InsnsInfo::insn_num(name))).to eq(InsnExt::insn_ret_num(InsnExt::insn_num(name)))}
    end
  end

  describe "::insn_stack_increase" do
    ary = [1,1]
    RubyVM::INSTRUCTION_NAMES.each do |name|
      case name
      when  "expandarray"
        it "should have the same return value of InsnExt::insn_stack_increase when #{name}" do
          ary1 = [0,0]
          ary2 = [0,1]
          expect(InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary1)).to eq(InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary1))
          expect(InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary2)).to eq(InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary2))
          expect(InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary1)).not_to eq( InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary2))
        end
      when  "send"
        it "should have the same return value of InsnExt::insn_stack_increase when #{name}" do
          case RUBY_VERSION[0..2]
          when /^1.9/  
            ary1 = [0,0,0,0]
            ary2 = [0,0,0,4]
          when /^2.0/
            ary1 = [{:orig_argc => 1, :flag => 1}]
            ary2 = [{:orig_argc => 1, :flag => 4}]
          end
          expect(InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary1)).to eq(InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary1))
          expect(InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary2)).to eq(InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary2))
          expect(InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary1)).not_to eq(InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary2))
        end
      when "invokesuper"
        it "should have the same return value of InsnExt::insn_stack_increase when #{name}" do
          case RUBY_VERSION[0..2]
          when /^1.9/
            ary1 = [0,0,0,0]
            ary2 = [0,0,4,0]
          when /^2.0/
            ary1 = [{:orig_argc => 1, :flag => 1}]
            ary2 = [{:orig_argc => 1, :flag => 4}]
          end
          expect(InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary1)).to eq(InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary1))
          expect(InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary2)).to eq(InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary2))
          expect(InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary1)).not_to eq(InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary2))
        end
      when "opt_send_simple"
        it "should have the same return value of InsnExt::insn_stack_increase when #{name}" do
          ary_opt = [{:orig_argc => 1}]
          expect(InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary_opt)).to eq(InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary_opt))
        end
      when "invokeblock"
        it "should have the same return value of InsnExt::insn_stack_increase when #{name}" do
          case RUBY_VERSION[0..2]
          when /^1.9/
            ary_inv = [1,0]
          when /^2.0/
            ary_inv = [{:orig_argc => 1}]
          end
          expect(InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary_inv)).to eq(InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary_inv))
        end
      else
        it "should have the same return value of InsnExt::insn_stack_increase when #{name}" do
          expect(InsnsInfo::insn_stack_increase(InsnsInfo::insn_num(name),ary)).to eq(InsnExt::insn_stack_increase(InsnExt::insn_num(name),ary))
        end
      end
    end
  end
end 
