module FlawDetector
  class BasicController
    def initialize(formatter = Formatter::CsvFormatter.new)
      @detectors = []
      @formatter = formatter
    end

    # @return [Boolean] true if no flaw found, otherwise false
    def run(file_or_ary)
      result = []
      ary = [file_or_ary] if file_or_ary.is_a?(String)
      ary ||= file_or_ary
      ary.each do |file|
        File.open(file) do |fp|
          dom = FlawDetector::parse_file(fp)
          @detectors.each do |analyzer|
            result += analyzer.analyze(dom)
          end
        end
      end
      @formatter.render(result)
      result.empty?
    end

    attr_accessor :detectors
  end
end
