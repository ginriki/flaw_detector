module FlawDetector
  module CodeModel
    class CfgNode
      def create_sibling(bb_name)
        cfg = CfgNode.new(bb_name, @insns_block)
        add_list(cfg)
      end

      def initialize(bb_name, insns_block)
        @next_nodes = []
        @prev_nodes = []
        @name = bb_name
        @insns_block = insns_block
        @leave = nil
        @dfst_parent = nil
        @dominators = nil
      end

      def inspect
        return "#{self.class.name}:#{self.object_id} @name='#{self.name}',@insns_block='#{self.insns_block}'>"
      end

      def add_next(node)
        @next_nodes << node
      end

      def add_prev(node)
        @prev_nodes << node
      end

      def set_leave(node)
        if entry == self
          @leave = node
        else
          entry.set_leave(node)
        end
      end

      def leave
        if entry == self
          @leave
        else
          entry.leave
        end
      end

      # @todo exclude...
      def last_line
        insns_frame.index2line(bb[0].last-1)
      end

      def each(&block)
        each_node_list do |name, node|
          block.call(name, node)
          node.next_nodes.each do |nnd|
            next unless nnd.name == :entry
            nnd.each_node_list(&block)
          end
        end
      end

      def each_dfst_node_by_preorder(&block)
        each_dfst_node(:preorder, &block)
      end

      def each_dfst_node_by_postorder(&block)
        each_dfst_node(:postorder, &block)
      end

      def each_dfst_node_by_reverse_postorder(&block)
        nodes = []
        each_dfst_node_by_postorder do |node|
          nodes << node
        end

        nodes.reverse_each(&block)
      end

      def each_node_list(&block)
        node_list.each(&block)
      end

      def entry
        node_list[:entry]
      end

      def node(bb_name)
        node_list[bb_name]
      end

      def total_node_count
        self.node_list.count
      end

      def bb
        @insns_block.raw_block_data[:extra][:basic_blocks][name]
      end

      def last_lineno
        @insns_block.index2line(bb[0].last+1)
      end

      # @todo support ISeqHeader::TYPE_BLOCK
      def dominate?(node)
        return false unless @insns_block == node.insns_block
        return false if insns_frame.type == ISeqHeader::TYPE_BLOCK
        return true if self.name == node.name
        idom = node
        while idom = @insns_block.domtree[idom.name] do
          return true if self.name == idom.name
        end
        return false
      end

      def is_dominance_frontier_of?(node)
        if node.prev_nodes.first == node.prev_nodes.last
          pfpl = plpf = []
        else
          pfpl = node.prev_nodes.first.dominators - node.prev_nodes.last.dominators
          plpf = node.prev_nodes.last.dominators - node.prev_nodes.first.dominators
        end
        pfpl.include?(self) || plpf.include?(self)
      end

      def dominators
        return @dominators if @dominators
        @dominators = []
        each_node_list do |name, node|
          @dominators << node if node.dominate?(self)
        end
        return @dominators
      end

      def visit_specified_dominators(&block)
        checked_nodes = []
        stack_of_nodes = [self]
        until stack_of_nodes.empty? do
          node = stack_of_nodes.pop
          next unless self.dominate?(node)
          next if checked_nodes.include?(node)
          checked_nodes << node
          n = block.call(node)
          case n
          when :first, :last
            next_nodes = [node.next_nodes.send(n)]
          when :all
            next_nodes = node.next_nodes
          when :none
            next_nodes = []
          else
            raise "unknown state"
          end
          next_nodes.each do |nnd|
            next if nnd.name == :entry
            stack_of_nodes << nnd
          end
        end
      end

      attr_reader :next_nodes,:prev_nodes,:name,:leave,:insns_block,:dfst_parent
      alias :insns_frame :insns_block

      protected
      attr_writer :dfst_parent

      def add_list(node)
        node_list[node.name] = node
      end

      def node_list
        @insns_block.cfg_node_list.keys
        @insns_block.cfg_node_list
      end

      def each_dfst_node(type = :preorder, position = :entry, found = [], &block)
        node = node_list[position]
        found << node

        block.call(node) if type == :preorder
        node.next_nodes.each do |nnd|
          next if nnd.name == :entry #skip another frame
          next if found.include?(nnd)
          nnd.dfst_parent = node
          each_dfst_node(type, nnd.name, found, &block)
        end
        block.call(node) if type == :postorder
      end
    end
  end
end
