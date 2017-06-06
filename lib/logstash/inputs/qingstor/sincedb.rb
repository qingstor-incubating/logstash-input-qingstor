require 'logstash/inputs/qingstor'
require 'fileutils'

# module used for record the download history
module LogStash
  module Inputs
    class Qingstor
      # define the class SinceDB::File
      class SinceDB
        def initialize(file)
          @sincedb_path = file
        end

        def newer?(date)
          Time.at(date) > read
        end

        def read
          if ::File.exist?(@sincedb_path)
            content = ::File.read(@sincedb_path).chomp.strip
            content.empty? ? Time.new(0) : Time.parse(content)
          else
            Time.new(0)
          end
        end

        def write(since = nil)
          since = Time.now if since.nil?
          dir = ::File.dirname(@sincedb_path)
          FileUtils.mkdir_p(dir) unless ::File.directory?(dir)
          ::File.open(@sincedb_path, 'w') { |file| file.write(since.to_s) }
        end
      end # class FILE
    end # class QingStor
  end # module Inputs
end # module LogStash
