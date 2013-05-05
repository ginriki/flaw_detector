module FlawDetector
  module Iseq
    class InstructionContainer
      attr_reader :insn
      def initialize(insn, header)
        @insn = insn
        @major_version = header[:major]
      end

      def major_version
        @major_version
      end

      def inspect
        @insn.inspect
      end
      
      def [](param)
        case param
        when Fixnum
          return @insn[param]
        when Range
          return @insn[param]
        when Symbol
          if param == :opcode
            return @insn[0]
          else
            return send("symbol_#{self[:opcode]}_v#{self.major_version}", param)
          end
        else
          raise "unknown param:#{param}"
        end
      end

      private

      def symbol_send_v1(param)
        case param
        when :mid
          return @insn[1]
        when :blockptr
          return @insn[3]
        end
      end

      def symbol_send_v2(param)
        case param
        when :mid
          return @insn[1][:mid]
        when :blockptr
          return @insn[1][:blockptr]
        else
          return symbol_send_v1(param)
        end
      end

      def symbol_putiseq_v1(param)
        case param
        when :blockptr
          return @insn[1]
        end
      end

      def symbol_defineclass_v1(param)
        case param
        when :blockptr
          return @insn[2]
        end
      end

      def symbol_invokesuper_v1(param)
        case param
        when :blockptr
          return @insn[2]
        end
      end

      alias :symbol_invokesuper_v2 :symbol_invokesuper_v1
      alias :symbol_putiseq_v2 :symbol_putiseq_v1
      alias :symbol_defineclass_v2 :symbol_defineclass_v1
    end
  end
end
