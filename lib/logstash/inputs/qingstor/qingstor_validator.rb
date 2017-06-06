require 'logstash/inputs/qingstor'
require 'qingstor/sdk'

# Validator for check the avaliablity of setting in QingStor
module QingstorValidator
  def bucket_valid?(bucket)
    res = bucket.head
    case res[:status_code]
    when 401
      raise LogStash::ConfigurationError,
            'Incorrect key id or access key.'
    when 404
      raise LogStash::ConfigurationError,
            'Incorrect bucket/region name.'
    end
    true
  end

  def prefix_valid?(prefix)
    if prefix.start_with?('/') || prefix.length >= 1024
      raise LogStash::ConfigurationError, 'Prefix must not start with '\
          + "'/' with length less than 1024"
    end
    true
  end

  def create_if_not_exist(bucket)
    return if bucket.head[:status_code] == 200
    res = bucket.put
    if res[:status_code] != 201
      @logger.error('ERROR : cannot create the bucket ', res[:message])
      raise LogStash::ConfigurationError, 'cannot create the bucket'
    end
  end # def create_if_not_exist
end # module QingstorValidator
