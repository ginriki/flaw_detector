module FlawDetector
  module CodeModel
    class CodeDocument
      def self.create(doc, filepath = "<compiled>")
        return CodeDocument.new(doc, filepath)
      end

      def top
        root
      end

      def select_methods(name=nil)
        select_some_type(ISeqHeader::TYPE_METHOD, name)
      end

      def select_classes(name=nil)
        class_name = nil
        class_name = "<class:#{name}>" if name
        select_some_type(ISeqHeader::TYPE_CLASS, class_name)
      end

      def select_class(name)
        root.each do |block|
          next unless block.type == ISeqHeader::TYPE_CLASS
          next unless block.name == "<class:#{name}>"
          return block
        end
        return nil
      end

      attr_reader :root
      attr_reader :filepath
      private
      def initialize(str, filepath)
        @root = InsnsFrame.new(str)
        @filepath = filepath
      end

      def select_some_type(type, name=nil)
        selects = []
        b = proc do |parent|
          parent.child_blocks.each do |frame|
            unless frame.type == type
              b.call(frame)
              next
            end
            if name.nil? || frame.name == name
              selects << frame
            end
          end
        end

        if root.type == type
          if name.nil? || root.name == name
            selects << frame
          end
        end
        b.call(root)
        selects
      end
    end
  end
end
