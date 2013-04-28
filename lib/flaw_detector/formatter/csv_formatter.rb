require 'csv'

module FlawDetector
  module Formatter
    class CsvFormatter
      def initialize(io = STDOUT)
        @io = io
      end
      
      # == Arguments & Return
      # _result_       :: [Array] array of hash. each hash key must be [:msgid,:file,:line,:summary,:description]
      # *Return* :: [String]
      def render(result)
        headers = [:msgid,:file,:line,:short_desc,:long_desc,:details]
        data = CSV.generate("", :row_sep => "\r\n", :headers => headers, :write_headers => true) do |csv|
          result.each do |row|
            csv << row.values_at(*headers)
          end
        end
        @io << data
      end
    end
  end
end
