module FlawDetector
  module Detector
    class NilFalsePathFlow
      NIL_CHECK_METHODS = [:nil?]
      VAR_BRANCH_KLASS = {:klass => [NilClass, FalseClass], :message => {:branchif => :last, :branchunless => :first}}
      # if methods return true, RCEV type is decided
      RCEV_KLASS_OF_METHODS = {
        :nil? => 
        {:klass => [NilClass],
          :message => {:branchif => :first, :branchunless => :last}}
      }
      REVERSE_EDGE = {:first => :last, :last => :first}
      NIL_METHODS = nil.methods
      FALSE_CLASS_METHODS = FalseClass.methods
      CALC_CODE = {:opt_plus => :+, :opt_minus => :-, :opt_mult => :*, :opt_div => :/, :opt_mod => :%,
        :opt_eq => :==, :opt_neq => :!=, :opt_lt => :<, :opt_le => :<=, :opt_gt => :>, :opt_ge => :>=,
        :opt_ltlt => :<<}
      def initialize
        
      end
      
      # == Arguments & Return
      # _dom_       :: 
      # *Return* :: [Array] array of hash. each hash key must be [:msgid,:file,:line,:short_desc,:long_desc,:details]
      def analyze(dom)
        result = []
        
        search_frames = dom.select_methods + [dom.top] + dom.select_classes
        search_frames.each do |frame|
          klass_specified_variable_list = []
          # *search
          frame.insns.each_with_index do |insn, index|
            next unless [:getlocal, :getdynamic].include?(insn[0])
            varframe, varname = frame.insn2variable(insn)
            obj_index,argnum = frame.find_use_insn_index_of_ret(index, insn)
            unless obj_index
              # @todo support using variable at multiple branchif ;ex) case-when syntax
              next
            end
            obj_insn = frame.raw_block_data[:body][:insns][obj_index]
            p_cfg = frame.find_cfg_node_by_insn_index(obj_index)
            klass_specified_edge = nil
            case obj_insn[0]
            when :send
              if argnum == 0 && RCEV_KLASS_OF_METHODS.has_key?(obj_insn[:mid]) #varnum is the receiver and method is a nil check
                next_obj_index,next_argnum = frame.find_use_insn_index_of_ret(obj_index, obj_insn)
                next_obj_insn = frame.raw_block_data[:body][:insns][next_obj_index]
                case next_obj_insn[0]
                when :branchif, :branchunless
                  klass_specified_edge = RCEV_KLASS_OF_METHODS[obj_insn[:mid]][:message][next_obj_insn[0]]
                  klass = RCEV_KLASS_OF_METHODS[obj_insn[:mid]][:klass]
                end
              end
            when :branchif, :branchunless
              klass_specified_edge = VAR_BRANCH_KLASS[:message][obj_insn[0]]
              klass = VAR_BRANCH_KLASS[:klass]
            end
            
            next unless klass_specified_edge
            ks_variable = {:specified_edge => klass_specified_edge,  :branch_node => p_cfg, :variable => {:frame => varframe, :name => varname, :klass => klass}, :already_checked => false}
            ks_variable[:complement_edge] = REVERSE_EDGE[ks_variable[:specified_edge]]
            nn = ks_variable[:branch_node].next_nodes
            tmperase = []
            tmperase << :complement_edge if nn.send(ks_variable[:specified_edge]).is_dominance_frontier_of?(nn.send(ks_variable[:complement_edge]))
            tmperase << :specified_edge if nn.send(ks_variable[:complement_edge]).is_dominance_frontier_of?(nn.send(ks_variable[:specified_edge]))
            tmperase.each{|k| ks_variable.delete(k)}

            klass_specified_variable_list << ks_variable
          end

          # *detection
          klass_specified_variable_list.each do |ks_variable|
            next if ks_variable[:already_checked]
            if ks_variable[:specified_edge]
              cfg = ks_variable[:branch_node].next_nodes.send(ks_variable[:specified_edge])
              cfg.visit_specified_dominators do |node|
                check_end, ng_list = check_nil_var_ref(node, ks_variable[:variable])
                ng_list.each do |elem|
                  line = elem[:frame].index2line(elem[:index])
                  result << FlawDetector::make_info(:file => dom.filepath, :line => line, :msgid => "NP_ALWAYS_FALSE", :params => [elem[:variable][:name]])
                end
                if check_end
                  next :none
                else
                  redundant = find_redundant_node(klass_specified_variable_list, node, ks_variable)
                  if redundant
                    redundant[:already_checked] = true
                    line = redundant[:branch_node].last_line
                    result << FlawDetector::make_info(:file => dom.filepath, :line => line, :msgid => "RCN_REDUNDANT_FALSECHECK_OF_FALSE_VALUE", :params => [redundant[:variable][:name], ks_variable[:branch_node].last_line])
                    next redundant[:specified_edge]
                  else
                    next :all
                  end
                end
              end
            end

            if ks_variable[:complement_edge]
              cfg = ks_variable[:branch_node].next_nodes.send(ks_variable[:complement_edge])
              cfg.visit_specified_dominators do |node|
                redundant = find_redundant_node(klass_specified_variable_list, node, ks_variable)
                if redundant
                  redundant[:already_checked] = true
                  line = redundant[:branch_node].last_line
                  result << FlawDetector::make_info(:file => dom.filepath, :line => line, :msgid => "RCN_REDUNDANT_FALSECHECK_OF_TRUE_VALUE", :params => [redundant[:variable][:name], ks_variable[:branch_node].last_line])
                  next redundant[:complement_edge]
                else
                  next :all
                end
              end
            end
            # [p_cfg's dominators - s_cfg's dominators] check send method except nil methods
            #TODO: add warning list if get localvar and nil checked. # deadcode
            #TODO: implements
          end
        end

        #* remove duplicate result
        #NOTE: it be caused that input code to analyzer has deadcode.
        return result
      end

      # @param variable [Hash] nil variable on node
      # @return [Boolean] check_end?
      # @return [Array] detected ngs
      # @todo remove false positive detection of neither compareable or replacement operator such as "<<"
      def check_nil_var_ref(node, variable)
        ng_list = [] # each element has keys: {:variable, :index, :frame}
        unless node.prev_nodes.first == node.prev_nodes.last
          # check setlocal opcode at dominance frontier
          pfpl = node.prev_nodes.first.dominators - node.prev_nodes.last.dominators
          plpf = node.prev_nodes.last.dominators - node.prev_nodes.first.dominators
          #TODO: return if pfpl/plpf have set localvar
        end
        
        frame = node.insns_frame

        node.bb[0].each do |index|
          insn = frame.insns[index]
          case insn[0]
          when :setlocal, :setdynamic
            varframe,varname = frame.insn2variable(insn)
            # return if insn of index set localvar
            return true, ng_list if variable[:name] == varname && variable[:frame] == varframe
          when :getlocal, :getdynamic
            varframe,varname = frame.insn2variable(insn)
            if variable[:name] == varname && variable[:frame] == varframe
              use_index, use_argnum = frame.find_use_insn_index_of_ret(index, insn)
              use_insn = frame.insns[use_index]
              case use_insn[0]
              when :send
                if (use_argnum == 0 && !NIL_METHODS.include?(use_insn[:mid])) ||
                    (use_argnum == 1 && CALC_CODE.values.include?(use_insn[:mid]) && !NIL_METHODS.include?(use_insn[:mid]))
                  ng_list << {:variable => variable, :index => use_index, :frame => frame}
                end
              when *(CALC_CODE.keys)
                # ASSERT: nil not operand method
                unless NIL_METHODS.include?(CALC_CODE[use_insn[0]])
                  ng_list << {:variable => variable, :index => use_index, :frame => frame}
                end
              end
            end
          end
        end
        return false, ng_list
      end

      def find_redundant_node(klass_specified_variable_list, node, ks_variable)
        redundant = klass_specified_variable_list.find do |other_info| # @todo sort by tree parent first
          next if other_info[:branch_node] == ks_variable[:branch_node]
          next unless other_info[:variable][:name] == ks_variable[:variable][:name] &&
            other_info[:variable][:frame] == ks_variable[:variable][:frame]
          next unless other_info[:branch_node] == node
          next unless (ks_variable[:variable][:klass] - other_info[:variable][:klass]).empty?
          true
        end
        return redundant
      end      
    end
  end
end
