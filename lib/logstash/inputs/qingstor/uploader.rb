require 'logstash/inputs/qingstor'
require 'qingstor/sdk'
require 'concurrent'

module LogStash
  module Inputs
    class Qingstor
      # define class Uploader to process upload jobs
      class Uploader
        require 'logstash/inputs/qingstor/qingstor_validator'
        include QingstorValidator

        TIME_BEFORE_RETRYING_SECONDS = 1
        DEFAULT_THREADPOOL = Concurrent::ThreadPoolExecutor.new(
          :min_thread => 1,
          :max_thread => 8,
          :max_queue => 2,
          :fallback_policy => :caller_runs
        )

        attr_reader :bucket, :prefix, :logger

        def initialize(bucket, prefix, logger)
          @bucket = bucket
          @prefix = prefix
          @logger = logger
          @workers_pool = DEFAULT_THREADPOOL
        end

        def upload_async(filename, filepath)
          @workers_pool.post do
            upload(filename, filepath)
          end
        end

        def upload(filename, filepath)
          create_if_not_exist(@bucket)
          file_md5 = Digest::MD5.file(filepath).to_s
          key = if @prefix.end_with?('/') || @prefix.empty?
                  @prefix + filename
                else
                  @prefix + '/' + filename
                end
          @logger.debug('uploading backup file', :file => filename)
          @bucket.put_object(key, 'content_md5' => file_md5,
                                  'body' => ::File.open(filepath))
        end

        def stop
          @workers_pool.shutdown
          @workers_pool.wait_for_termination(nil)
        end
      end # class Uploader
    end # class QingStor
  end # module Inputs
end # module LogStash
