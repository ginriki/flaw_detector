module FlawDetector
  module CodeModel
    class InsnsFrame
      def initialize(iseq_data,pblock=nil, insns_pos=nil)
        @raw_block_data = iseq_data
        @child_blocks = []
        @parent = pblock
        @insns_pos = insns_pos
        @cfg_node_list = {}
        @domtree = nil
        
        if @raw_block_data
          @raw_block_data[:extra][:insns_pos_to_operand_iseq].each do |insns_pos, raw_block|
            if raw_block
              @child_blocks << InsnsFrame.new(raw_block, self, insns_pos)
            else
              @child_blocks << InsnsFrame.new(nil, self, insns_pos)
            end
          end
        end
      end

      def inspect
        return "#{self.class.name}:#{self.object_id} @name='#{self.name}',@type='#{self.type}',@insns_pos='#{@insns_pos}',@child_frames=#{@child_blocks}>"
      end

      def insns_pos_in_parent_body
        @insns_pos
      end

      def name
        if @raw_block_data
          @raw_block_data[:header][:name].to_s
        else
          ""
        end
      end

      def type
        if @raw_block_data
          @raw_block_data[:header][:type]
        else
          nil
        end
      end

      def insns
        if @raw_block_data
          s = @raw_block_data[:body][:insns].clone
        else
          s = []
        end
        s.freeze
      end

      def each(&block)
        block.call(self)
        @child_blocks.each(&block)
      end

      def basic_blocks
        raw_block_data[:extra][:basic_blocks].dup.freeze
      end

      # == Arguments & Return
      # _varname_ :: [Symbol] variable name
      # *Return* :: [Integer] idx which is operand for getlocal, setlocal and so on
      def varname2idx(varsym)
        cnt = raw_block_data[:header][:locals].count
        index = raw_block_data[:header][:locals].find_index(varsym)
        if index
          return cnt - index + 1
        else
          return nil
        end
      end

      # == Arguments & Return
      # _idx_ :: [Integer] idx which is operand for getlocal, setlocal and so on
      # *Return* :: [Symbol] variable name
      def idx2varname(idx)
        cnt = raw_block_data[:header][:locals].count
        raw_block_data[:header][:locals][cnt+1-idx]
      end

      def insn2variable(insn)
        frame = nil
        varname = nil
        case insn[0]
        when :getlocal,:setlocal
          idx = insn[1]
          frame = self
          varname = frame.idx2varname(idx)
        when :getdynamic,:setdynamic
          idx = insn[1]
          up_frame = insn[2]
          frame = self
          insn[2].times{frame = frame.parent}
          varname = frame.idx2varname(idx)        
        else
          raise 'unknown state'
        end
        return frame, varname
      end

      def entry_cfg_node
        unless @cfg_node_list[:entry]
          top_of_block = self
          while top_of_block.raw_block_data[:header][:type] == ISeqHeader::TYPE_BLOCK do
            top_of_block = top_of_block.parent
            unless top_of_block
              raise "unknown state"
            end
          end
          top_of_block.make_cfg
          unless @cfg_node_list[:entry]
            #ASSERT: make_cfg method creates cfg nodes of top/method and child blocks
            raise "unknown state"
          end
        end
        @cfg_node_list[:entry]
      end

      def find_cfg_node_by_insn_index(index)
        entry_cfg_node
        @cfg_node_list.each do |key, val|
          return val if val.bb[0].include?(index)
        end        
      end

      def find_insn_index_of_send_obj(index, insn)
        find_def_insn_index_of_arg(index, insn)
      end

      def find_use_insn_index_of_ret(index, insn, retnum=0)
        if retnum >= InsnExt::insn_ret_num(InsnExt::insn_num(insn[0]))
          raise "wrong argument: retnum=#{retnum}"
        end

        depth = retnum
        obj_index = nil
        start_index = index+1
        cfg_node = find_cfg_node_by_insn_index(index)
        unless cfg_node.bb[0].include?(start_index)
          if cfg_node.next_nodes.count == 1 #TODO: exclude different frame
            cfg_node = cfg_node.next_nodes.first
            start_index = cfg_node.bb[0].first
          else
            cfg_node = nil
          end
        end
        while cfg_node do 
          (start_index...(cfg_node.bb[0].last)).each do |tmp_index|
            tmp_insn = self.raw_block_data[:body][:insns][tmp_index]
            tmp_ret = InsnExt::insn_ret_num(InsnExt::insn_num(tmp_insn[0]))
            tmp_inc = InsnExt::insn_stack_increase(InsnExt::insn_num(tmp_insn[0]), tmp_insn[1..-1])
            depth += tmp_inc - tmp_ret
            if depth < 0
              obj_index = tmp_index
              break
            end
            depth += tmp_ret
          end
          break if obj_index
          if cfg_node.next_nodes.count == 1 #TODO: exclude different frame
            cfg_node = cfg_node.next_nodes.first
            start_index = cfg_node.bb[0].first
          else
            cfg_node = nil
          end
        end

        obj_argnum = nil
        if obj_index
          obj_argnum = -(depth + 1)
        end
        return obj_index, obj_argnum
      end

      def find_def_insn_index_of_arg(index, insn, argnum=0)
        inc = InsnExt::insn_stack_increase(InsnExt::insn_num(insn[0]), insn[1..-1])
        ret = InsnExt::insn_ret_num(InsnExt::insn_num(insn[0]))
        depth = (inc - ret) + argnum
        obj_index = nil
        end_index = index
        cfg_node = find_cfg_node_by_insn_index(index)
        unless cfg_node.bb[0].include?(index-1)
          if cfg_node.prev_nodes.count == 1 #TODO: exclude different frame
            cfg_node = cfg_node.prev_nodes.first
            end_index = cfg_node.bb[0].last
          else
            cfg_node = nil
          end
        end
        while cfg_node
          ((cfg_node.bb[0].first)...end_index).reverse_each do |tmp_index|
            rinsn = self.raw_block_data[:body][:insns][tmp_index]
            tmp_ret = InsnExt::insn_ret_num(InsnExt::insn_num(rinsn[0]))
            if (depth + tmp_ret) >= 0
              obj_index = tmp_index
              break
            end
            depth += InsnExt::insn_stack_increase(InsnExt::insn_num(rinsn[0]), rinsn[1..-1])
          end
          break if obj_index
          if cfg_node.prev_nodes.count == 1 #TODO: exclude different frame
            cfg_node = cfg_node.prev_nodes.first
            end_index = cfg_node.bb[0].last
          else
            cfg_node = nil
          end
        end
        
        obj_retnum = nil
        if obj_index
          tmp_insn = self.raw_block_data[:body][:insns][obj_index]
          tmp_ret = InsnExt::insn_ret_num(InsnExt::insn_num(tmp_insn[0]))
          obj_retnum = depth + tmp_ret
        end

        return obj_index, obj_retnum
      end

      def index2line(index)
        i = self.raw_block_data[:extra][:insns_pos_to_lineno].find_index{|elem| elem[0].include?(index)}
        if i
          self.raw_block_data[:extra][:insns_pos_to_lineno][i][1]
        else
          nil
        end
      end

      def domtree
        @domtree if @domtree
        e = entry_cfg_node
        idom = {}
        dfsn = {}
        val = 0
        e.each_dfst_node_by_reverse_postorder do |node|
          dfsn[node.name] = val
          val += 1
        end
        
        e.each_node_list do |name, node|
          idom[node.name] = node.dfst_parent
        end

        nca = lambda do |x,y|
          while (x != y) do
            x_dfsn = if x then dfsn[x.name] else nil end
            y_dfsn = if y then dfsn[y.name] else nil end
            if x_dfsn > y_dfsn
              x = idom[x.name]
            elsif x_dfsn < y_dfsn
              y = idom[y.name]
            end
          end
          x
        end

        change_flag = true
        while(change_flag) do
          change_flag = false
          e.each_dfst_node_by_postorder do |v|
            v.prev_nodes.each do |succ|
              next if succ.name == :leave
              tmp_idom = nca.call(idom[v.name], succ)
              if tmp_idom != idom[v.name]
                change_flag = true
                idom[v.name] = tmp_idom
              end
            end
          end
        end
        @domtree = idom
      end

      attr_reader :parent, :child_blocks, :raw_block_data, :cfg_node_list

      protected
      def make_cfg
        bb_name = :entry
        pcfg = CfgNode.new(bb_name, self)
        @cfg_node_list[bb_name] = pcfg
        make_cfg_inter(pcfg)
        
        node = pcfg.node(:leave)
        unless node
          node = pcfg.create_sibling(:leave)
        end
        pcfg.set_leave(node)
        
        return pcfg
      end

      private
      def make_cfg_inter(pcfg)
        new_node = []
        data = self.raw_block_data
        bbs = data[:extra][:basic_blocks]
        pcfg.bb[1..-1].each do |pos|
          next if [:exception].include?(pos)
          key, val = bbs.find{|key,val|
            if pos == :leave && key == :leave
              true
            else
              val[0].include?(pos)
            end
          }
          
          unless key
            raise "unknown state"
          end
          node = pcfg.node(key)
          unless node
            node = pcfg.create_sibling(key)
            new_node << node
          end
          pcfg.add_next(node)
          node.add_prev(pcfg)
        end
        
        @child_blocks.each do |b|
          next unless b.raw_block_data
          next unless b.raw_block_data[:header][:type] == ISeqHeader::TYPE_BLOCK
          if pcfg.bb[0].include?(b.insns_pos_in_parent_body)
            node = b.make_cfg
            pcfg.add_next(node)
            node.add_prev(pcfg)
            
            #TODO: is this ok? (or should use :break exception?)
            pcfg.next_nodes.first.add_prev(node.leave)
            node.leave.add_next(pcfg.next_nodes.first)
            break
          end
        end
        new_node.each {|n| make_cfg_inter(n)}
      end
    end
  end
end
