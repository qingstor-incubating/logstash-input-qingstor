def fetch_events(settings)
  queue = []
  qs = LogStash::Inputs::Qingstor.new(settings)
  qs.register
  qs.process_files(queue)
  queue
end  

def qs_init_config(access_key_id = ENV['access_key_id'],
                   secret_access_key = ENV['secret_access_key'])
  return QingStor::SDK::Config.init access_key_id, secret_access_key
end 

def qs_init_bucket(bucket = ENV['bucket'], region = ENV['region'])
  config = qs_init_config
  properties = {'bucket-name' => bucket, 'zone' => region }
  return QingStor::SDK::Bucket.new(config, properties)
end 

def upload_file(local_file, remote_file)
  bucket = qs_init_bucket
  file = File.expand_path(File.join(File.dirname(__FILE__), local_file))
  md5_string = Digest::MD5.file(file).to_s
  bucket.put_object remote_file, { 
      'content_md5' => md5_string,
      'body' => File.open(file)
  }
end 

def delete_remote_file(key)
  bucket = qs_init_bucket
  bucket.delete_object key
end

def list_remote_file(bucket = ENV['bucket'], region = ENV['region'])
  bucket = qs_init_bucket(bucket, region)
  return bucket.list_objects[:keys]
end

def clean_and_delete_bucket(bucket)
  bucket = qs_init_bucket(bucket)
  bucket.list_objects[:keys].each do |file|
    bucket.delete_object file[:key]
  end 
  bucket.delete
end 