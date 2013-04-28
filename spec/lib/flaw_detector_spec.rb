require 'spec_helper'
require 'yaml'
require 'tempfile'

describe FlawDetector do
  def flaws_from_comment(filename, code)
    result = []
    code.split("\n").each_with_index do |line, lineno_zero_basis|
      next unless line =~ /#\*\*([\w_]+)(,([\w,]+))*\*\*/
      lineno = lineno_zero_basis + 1
      params = if $3 then $3.split(",") else [] end
      result << FlawDetector::make_info(:file => filename, :line => lineno, :msgid => $1, :params => params)
    end
    result
  end

  describe "::NilVarDereference#analyze" do
    let(:nvd){ FlawDetector::Detector::NilFalsePathFlow.new}

    context "refer a variable which don't have def" do
      before{
        code =<<EOF
        def nil_var_ref(a)
          if a
            i = 1
          else
            # i's type is Nil
            puts(i + 1) # will be detected
          end
          return i
        end
        nil_var_ref(1)
EOF
      }
      it 'should detect nil variable dereference'
    end

    context "NP_ALWAYS_FALSE exists" do
      let(:code){
        <<EOF
        def nil_var_ref(a)
          if a
            rl = a + 1
            rl = 1 + a
          elsif
            rl = a + 1  #**NP_ALWAYS_FALSE,a**
            rl = 1 + a  #**NP_ALWAYS_FALSE,a**
          end
          return rl
        end
        nil_var_ref(1)
EOF
      }
      let(:dom){FlawDetector::parse(code)}
      it {expect(nvd.analyze(dom)).to eq(flaws_from_comment("<compiled>", code))}
    end

    context "Falsecheck of value previously dereferenced" do
      let(:code){
        <<EOF
          a.times do |i|
            some_method1(i+a)
          end
          if a #**RCN_REDUNDANT_FALSECHECK_WOULD_HAVE_BEEN_A_NPE,a**
            some_method2(a)
          end
EOF
      }
      let(:dom){FlawDetector::parse(code)}
      #it {expect(nvd.analyze(dom)).to eq(flaws_from_comment("<compiled>", code))}
      it "Falsecheck of value previously dereferenced"
    end

    context "RCN_REDUNDANT_FALSECHECK_OF_FALSE_VALUE exists" do
      let(:code) {
        code =<<EOF
        def nil_var_ref(a)
          if a
            rl = a + 1
          elsif a #**RCN_REDUNDANT_FALSECHECK_OF_FALSE_VALUE,a,2**
            rl = 1
          else
            rl = 1
          end
        end
        nil_var_ref(1)
EOF
      }
      let(:dom){FlawDetector::parse(code)}
      it {expect(nvd.analyze(dom)).to eq(flaws_from_comment("<compiled>", code))}
    end

    context "complex error exists" do
      let(:code) {
        code =<<EOF
        def nil_var_ref(a)
          if a
            rl = a + 1
          elsif a      #**RCN_REDUNDANT_FALSECHECK_OF_FALSE_VALUE,a,2**
            rl = 1 + a 
          else
            rl = a + 1 #**NP_ALWAYS_FALSE,a**
          end
        end
        nil_var_ref(1)
EOF
      }
      let(:dom){FlawDetector::parse(code)}
      it {expect(nvd.analyze(dom)).to eq(flaws_from_comment("<compiled>", code))}
    end

    context "complex error exists2" do
      let(:code) {
        code =<<EOF
        def nil_var_ref(a)
          if a.nil?
            rl = a + 1  #**NP_ALWAYS_FALSE,a**
          elsif a.nil?  #**RCN_REDUNDANT_FALSECHECK_OF_TRUE_VALUE,a,2**
            rl = a + 1
          else
            rl = 1 + a
          end
        end
        nil_var_ref(1)
EOF
      }
      let(:dom){FlawDetector::parse(code)}
      it {expect(nvd.analyze(dom)).to eq(flaws_from_comment("<compiled>", code))}
    end

    describe "bug fixed" do
      context "no error1" do
        let(:code){
          <<EOF
          def find_def_insn_index_of_arg(index, insn, argnum=0)
            if index
            elsif insn
            end
          end
EOF
        }
        let(:dom){FlawDetector::parse(code)}
        it {expect(nvd.analyze(dom)).to eq(flaws_from_comment("<compiled>", code))}
      end
      context "no RCN_REDUNDANT_NULLCHECK_OF_NULL_VALUE" do
        let(:code){
          <<EOF
            namespace = "hogehoge"
            unnamespaced = self.sub(/^::/, '') if namespace
            param_key    = (namespace ? _singularize(unnamespaced) : singular).freeze
EOF
        }
        let(:dom){FlawDetector::parse(code)}
        it {expect(nvd.analyze(dom)).to eq(flaws_from_comment("<compiled>", code))}
      end
      context "no undefined method" do
        let(:code){
          <<EOF
          def _parse_validates_options(options) #:nodoc:
            case options
            when TrueClass
              {}
            when Hash
              options
            when Range, Array
              { :in => options }
            else
             { :with => options }
            end
          end
EOF
        }
        let(:dom){FlawDetector::parse(code)}
        it {expect(nvd.analyze(dom)).to eq(flaws_from_comment("<compiled>", code))}
      end

      context "no undefined method" do
        let(:code){
          <<-'EOF'
          def human_attribute_name(attribute, options = {})
            defaults  = []
            parts     = attribute.to_s.split(".")
            attribute = parts.pop
            namespace = parts.join("/") unless parts.empty?

            if namespace
              lookup_ancestors.each do |klass|
                defaults << :"#{self.i18n_scope}.attributes.#{klass.model_name.i18n_key}/#{namespace}.#{attribute}"
              end
            else
              lookup_ancestors.each do |klass|
                defaults << :"#{self.i18n_scope}.attributes.#{klass.model_name.i18n_key}.#{attribute}"
              end
            end
            
            defaults << options.delete(:default) if options[:default]
          end
          EOF
        }
        let(:dom){FlawDetector::parse(code)}
        it {expect(nvd.analyze(dom)).to eq(flaws_from_comment("<compiled>", code))}
      end
    end
  end
  describe "::CodeModel::CodeDocument" do
    context "one branch code in a method" do 
      before {
        code =<<EOF
        def nil_var_ref(a)
          if a
            i = 1
          else
            # i's type is Nil
            puts(i + 1)
          end
          return i
        end
        nil_var_ref(1)
EOF
        @dom = FlawDetector::parse(code)
      }
        
      it 'should have no branch in the top frame' do
        cfg = @dom.root.entry_cfg_node
        branches_cnt = 0
        cfg.each do |name, node|
          if node.next_nodes.count >= 2
            branches_cnt += 1
          end
        end
        expect(branches_cnt).to eq(0)
      end

      it 'should have one branch in the method frame' do
        cfg = @dom.select_methods("nil_var_ref").first.entry_cfg_node
        branches_cnt = 0
        cfg.each do |name, node|
          if node.next_nodes.count >= 2
            branches_cnt += 1
          end
        end
        expect(branches_cnt).to eq(1)
      end
    end

    context "two branches code in a block in a method" do 
      before {
        code =<<EOF
        def one_branch_in_block
          puts("aaa")
          1.upto(3) do |num|  #a branch
            if num > 2        #a branch
              puts(num)
            end
          end
          puts("bbb")
        end
EOF
        @dom = FlawDetector::parse(code)
      }
        
      it 'should have no branch in the top frame' do
        cfg = @dom.root.entry_cfg_node
        branches_cnt = 0
        cfg.each do |name, node|
          if node.next_nodes.count >= 2
            branches_cnt += 1
          end
        end
        expect(branches_cnt).to eq(0)
      end

      it 'should have two branches in the method frame' do
        cfg = @dom.select_methods("one_branch_in_block").first.entry_cfg_node
        branches_cnt = 0
        cfg.each do |name, node|
          if node.next_nodes.count >= 2
            branches_cnt += 1
          end
        end
        expect(branches_cnt).to eq(2)
      end

      it 'each send instruction has obj of [:putspecialobject,1]' do
        block = @dom.root
        block.raw_block_data[:body][:insns].each_with_index do |insn, index|
          next unless insn[0] == :send
          obj_index,argnum = block.find_insn_index_of_send_obj(index, insn)
          obj_insn = block.raw_block_data[:body][:insns][obj_index]
        end
      end

      it 'each send instruction has obj of [:putnil] or [:putobject,1]' do
        block = @dom.select_methods("one_branch_in_block").first
        block.raw_block_data[:body][:insns].each_with_index do |insn, index|
          next unless insn[0] == :send
          obj_index,argnum = block.find_insn_index_of_send_obj(index, insn)
          obj_insn = block.raw_block_data[:body][:insns][obj_index]
        end
      end
    end

    context "one branch code in a proc in a method" do 
      before {
        code =<<-EOF
        def one_branch_in_block
          pr = proc {|num| p num} #a branch
          1.upto(3,&pr)
          puts("bbb")
        end
        EOF
        @dom = FlawDetector::parse(code)
      }
        
      it 'should have no branch in the top frame' do
        cfg = @dom.root.entry_cfg_node
        branches_cnt = 0
        cfg.each do |name, node|
          if node.next_nodes.count >= 2
            branches_cnt += 1
          end
        end
        expect(branches_cnt).to eq(0)
      end

      it 'should have one branch in the method frame' do
        cfg = @dom.select_methods("one_branch_in_block").first.entry_cfg_node
        branches_cnt = 0
        cfg.each do |name, node|
          if node.next_nodes.count >= 2
            branches_cnt += 1
          end
        end
        expect(branches_cnt).to eq(1)
      end

      it 'each send instruction has obj of [:putnil] or [:putobject,1]' do
        block = @dom.select_methods("one_branch_in_block").first
        block.raw_block_data[:body][:insns].each_with_index do |insn, index|
          next unless insn[0] == :send
          obj_index,argnum = block.find_insn_index_of_send_obj(index, insn)
          obj_insn = block.raw_block_data[:body][:insns][obj_index]
        end
      end

    end

    context "two branches code in a block in a method of SomeClass" do 
      before {
        code =<<EOF
        class SomeClass
          def one_branch_in_block
            puts("aaa")
            1.upto(3) do |num|  #a branch
              if num > 2        #a branch
                puts(num)
              end
            end
            puts("bbb")
          end
        end
EOF
        @dom = FlawDetector::parse(code)
      }
        
      it 'should have no branch in the top frame' do
        cfg = @dom.root.entry_cfg_node
        branches_cnt = 0
        cfg.each do |name, node|
          if node.next_nodes.count >= 2
            branches_cnt += 1
          end
        end
        expect(branches_cnt).to eq(0)
      end

      it 'each send instruction has obj of [:putspecialobject,1]' do
        block = @dom.select_class("SomeClass")
        block.raw_block_data[:body][:insns].each_with_index do |insn, index|
          next unless insn[0] == :send
          obj_index,argnum = block.find_insn_index_of_send_obj(index, insn)
          obj_insn = block.raw_block_data[:body][:insns][obj_index]
        end
      end
    end

    context "two branches and a throw for return in a block in a method" do 
      before {
        code =<<EOF
        def one_branch_in_block
          puts("aaa")
          1.upto(3) do |num|  #a branch
            if num > 2        #a branch
              puts(num)
            else
              return          #throw
            end
          end
          puts("bbb")
        end
EOF
        @dom = FlawDetector::parse(code)
      }
        
      it 'should have two branches in the method frame'
      it 'should have outer in the break\'s basic block'
    end

    context "two branches and a throw for break code in a block in a method" do 
      before {
        code =<<EOF
        def one_branch_in_block
          puts("aaa")
          1.upto(3) do |num|  #a branch
            if num > 2        #a branch
              puts(num)
            else
              break          #throw
            end
          end
          puts("bbb")
        end
EOF
        @dom = FlawDetector::parse(code)
      }
        
      it 'should have two branches in the cfg'
      it 'should have outer in the break\'s basic block'
    end

  end

  USE_OPS = [:getlocal, :getspecial, :getdynamic, :getinstancevariable, :getclassvariable, :getconstant, :getglobal]
  describe "::InsnBlock" do
    context "one branch code in a method" do 
      before {
        code =<<EOF
        def nil_var_ref(a)
          if a # use at :branchif and arg0
            rl = a + 1  #*flaw*
            rl = 1 + a  #*flaw*
          elsif a.nil?  #use at send and arg0
            rl = a + 1  #*flaw*
            rl = 1 + a  #*flaw*
          else
            rl = 1 + a #use at optplus
            rl = a + 1 #use at optplus
          end
          some_method(1,2,a) # use at send and arg3
          a.times do |i| #*flaw*
            puts(i)
          end
          return i
        end
        nil_var_ref(1)
EOF
        @dom = FlawDetector::parse(code)
      }
      it 'use def' do
        block = @dom.select_methods("nil_var_ref").first
        block.raw_block_data[:body][:insns].each_with_index do |insn, index|
          next unless USE_OPS.include?(insn[0])
          obj_index,argnum = block.find_use_insn_index_of_ret(index, insn)
          obj_insn = block.raw_block_data[:body][:insns][obj_index]
          robj_index,retnum = block.find_def_insn_index_of_arg(obj_index, obj_insn, argnum)
          robj_insn = block.raw_block_data[:body][:insns][robj_index]
          expect(robj_index).to eq(index)
        end
        a = block.domtree
        a.each do |key, val|
          next unless val
          #p "node: #{key}, idom: #{val.name}"
          #p val.dominators.count
        end
      end

    end

    context "two branches code in a block in a method of SomeClass" do 
      before {
        code =<<EOF
        class SomeClass
          def one_branch_in_block
            puts("aaa")
            1.upto(3) do |num|  #a branch
              if num > 2        #a branch
                puts(num)
              end
            end
            puts("bbb")
          end
        end
        obj = SomeClass.new
EOF
        @dom = FlawDetector::parse(code)
      }
        
      it 'should have no branch in the top frame' do
        block = @dom.root
        block.raw_block_data[:body][:insns].each_with_index do |insn, index|
          next unless USE_OPS.include?(insn[0])
          obj_index,argnum = block.find_use_insn_index_of_ret(index, insn)
          obj_insn = block.raw_block_data[:body][:insns][obj_index]
          robj_index,retnum = block.find_def_insn_index_of_arg(obj_index, obj_insn, argnum)
          robj_insn = block.raw_block_data[:body][:insns][robj_index]
          expect(robj_index).to eq(index)
        end
      end

      it 'each send instruction has obj of [:putspecialobject,1]' do
        block = @dom.select_class("SomeClass")
        block.raw_block_data[:body][:insns].each_with_index do |insn, index|
          next unless USE_OPS.include?(insn[0])
          obj_index,argnum = block.find_use_insn_index_of_ret(index, insn)
          obj_insn = block.raw_block_data[:body][:insns][obj_index]
          robj_index,retnum = block.find_def_insn_index_of_arg(obj_index, obj_insn, argnum)
          robj_insn = block.raw_block_data[:body][:insns][robj_index]
          
          expect(robj_index).to eq(index)
        end
      end
    end

  end

end
