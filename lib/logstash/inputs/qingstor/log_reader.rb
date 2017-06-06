require 'logstash/inputs/qingstor'
require 'zlib'

module LogStash
  module Inputs
    class Qingstor
      # define class LogReader to read log files
      class LogReader
        attr_accessor :filepath

        def initialize(filepath)
          @filepath = filepath
        end

        def read_file(&block)
          if gzip?(@filepath)
            read_gzip_file(block)
          else
            read_plain_file(block)
          end
        end

        def read_gzip_file(block)
          Zlib::GzipReader.open(@filepath) do |decoder|
            decoder.each_line { |line| block.call(line) }
          end
        rescue Zlib::Error, Zlib::GzipFile::Error => e
          @logger.error('Gzip codec: Cannot uncompress the file',
                        :filepath => @filepath)
          raise e
        end

        def read_plain_file(block)
          ::File.open(@filepath, 'rb') do |file|
            file.each(&block)
          end
        end

        def valid_format?(filepath)
          logger?(filepath) || gzip?(filepath)
        end

        def logger?(filepath)
          filepath.end_with?('.log', '.txt')
        end

        def gzip?(filepath)
          filepath.end_with?('.gz')
        end
      end # class LogReader
    end # class QingStor
  end #  module Inputs
end # module LogStash
