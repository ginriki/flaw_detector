require "flaw_detector/version"
require "flaw_detector/controller"
require "flaw_detector/message"
require "flaw_detector/formatter/csv_formatter"
require "flaw_detector/detector/nil_false_path_flow"
require "flaw_detector/code_model/code_document"
require "flaw_detector/code_model/insns_frame"
require "flaw_detector/code_model/cfg_node"
require "flaw_detector/iseq/instruction_container"
require File.expand_path("../../ext/insns_ext/insn_ext.rb", __FILE__)

module FlawDetector
  OPERAND_0 = 1
  OPERAND_1 = 2
  OPERAND_2 = 3
  OPERAND_3 = 4
  
  module ISeqHeader
    TYPE_TOP = :top
    TYPE_CLASS = :class
    TYPE_METHOD = :method
    TYPE_BLOCK = :block
  end

  include CodeModel
  
  # (key,val) = (opcode, operand number from 0)
  INSNS_HAVE_ISEQ_IN_OPERAND = {"putiseq" => OPERAND_0, "defineclass" => OPERAND_1, "send" => OPERAND_2, "invokesuper" => OPERAND_1}
  # ASSERT: operand number 0 is offset
  INSNS_OF_BRANCH = ["branchif", "branchunless"]
  
  def parse(code_str, filepath="<compiled>")
    tmp_compile_option = RubyVM::InstructionSequence.compile_option
    doc = nil
    begin
      RubyVM::InstructionSequence.compile_option = false
      isqns = RubyVM::InstructionSequence.compile(code_str)
      data = iseq_parse(isqns.to_a)
      doc = CodeDocument.create(data, filepath)
    ensure
      RubyVM::InstructionSequence.compile_option = tmp_compile_option
    end
    return doc
  end

  def parse_file(file)
    case file
    when String
      code_str = File.open(file, "r"){|f| f.read}
      filepath = file
    when File
      code_str = file.read
      filepath = file.path
    when IO
      code_str = file.read
      filepath = "<compiled>"
    else
      raise "not support class#{file.class}"
    end
    parse(code_str, filepath)
  end
  
  def iseq_parse(iseq)
    return nil unless iseq
    
    header = {}
    header[:magic] = iseq[0]
    header[:major] = iseq[1]
    header[:minor] = iseq[2]
    header[:format_type] = iseq[3]
    header[:misc] = iseq[4]
    header[:name] = iseq[5]
    header[:filename] = iseq[6]
    header[:filepath] = iseq[7]
    header[:line_no] = iseq[8]
    header[:type] = iseq[9]
    header[:locals] = iseq[10]
    header[:args] = iseq[11]
    header[:exceptions] = iseq[12]
    
    insns = []
    insns_pos_to_lineno = []
    label_pos = {}
    lineno_and_insns_pos = [nil,nil]
    insns_pos_to_operand_iseq = {}
    branch_info = [] # element = {:pos =>, :label =>}
    basic_block = [] # element type is (Range, Array). It is guaranteed that each element Range doesn't overlap
    tmp_bb_start_pos = 0
    
    iseq[13].each do |mixed|
      case mixed
      when Array # instruction
        insns << Iseq::InstructionContainer.new(mixed, header)
        opcode = mixed.first.to_s
        if INSNS_HAVE_ISEQ_IN_OPERAND.keys.include?(opcode)
          iseq_in_operand = iseq_parse(insns.last[:blockptr])
          insn_pos = insns.count-1
          insns_pos_to_operand_iseq[insn_pos] = iseq_in_operand
          
          #replace to link
          #mixed[operand_num] = insn_pos
          
          if insns_pos_to_operand_iseq[insn_pos] &&
              insns_pos_to_operand_iseq[insn_pos][:header][:type] == ISeqHeader::TYPE_BLOCK
            # NOTE: bb is changed becase iseq of block type may have break, raise, or etc...
            if tmp_bb_start_pos < insn_pos
              basic_block << [tmp_bb_start_pos...insn_pos, insn_pos]
            end
            basic_block << [insn_pos...(insn_pos+1), insn_pos+1, :exception]
            tmp_bb_start_pos = insns.count
          end
        elsif INSNS_OF_BRANCH.include?(opcode)
          basic_block << [tmp_bb_start_pos...insns.count, mixed[OPERAND_0], insns.count]
          tmp_bb_start_pos = insns.count
        elsif opcode == "jump"
          basic_block << [tmp_bb_start_pos...insns.count, mixed[OPERAND_0]]
          tmp_bb_start_pos = insns.count            
        elsif opcode == "leave"
          basic_block << [tmp_bb_start_pos...insns.count, :leave]
          tmp_bb_start_pos = insns.count
        end
      when Fixnum # lineno
        if lineno_and_insns_pos[0]
          range = lineno_and_insns_pos[1]...(insns.count)
          insns_pos_to_lineno << [range, lineno_and_insns_pos[0]]
        end
        lineno_and_insns_pos[0] = mixed
        lineno_and_insns_pos[1] = insns.count
      when Symbol # label
        label_pos[mixed] = insns.count
        basic_block << [tmp_bb_start_pos...insns.count, insns.count]
        tmp_bb_start_pos = insns.count
      end
    end
    if lineno_and_insns_pos[0]
      if insns_pos_to_lineno.empty? || !insns_pos_to_lineno.last.include?(insns.count-1)
        range = lineno_and_insns_pos[1]...(insns.count)
        insns_pos_to_lineno << [range, lineno_and_insns_pos[0]]
      end
    end
    # remove redundant bb
    basic_block.reject! {|bb| bb[0].to_a.size == 0}
    basic_block.each do |bb|
      bb.map! do |elem|
        if elem.to_s =~ /label_.+/
          label_pos[elem]
        else
          elem
        end
      end
    end
    #TODO: add remove redundant bb code

    #set name
    cnt = 0
    bs = {}
    basic_block.each do |bb|
      sym = "bb_#{bs.count}".to_sym
      bs[sym] = bb
    end
    bs[:entry] = [0...0,0]
    bs[:leave] = [0...0]

    body = {}
    body[:insns] = insns
    
    extra = {}
    extra[:insns_pos_to_lineno] = insns_pos_to_lineno
    extra[:label_pos] = label_pos
    extra[:insns_pos_to_operand_iseq] = insns_pos_to_operand_iseq
    extra[:basic_blocks] = bs

    return {:header => header, :body => body, :extra => extra}
  end

  module_function :iseq_parse, :parse, :make_info, :parse_file
end
