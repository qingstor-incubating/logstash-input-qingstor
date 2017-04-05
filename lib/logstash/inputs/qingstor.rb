# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "qingstor/sdk"
require "fileutils"
require "tmpdir"

class LogStash::Inputs::Qingstor < LogStash::Inputs::Base
  require "logstash/inputs/qingstor/qingstor_validator"
  config_name "qingstor"

  default :codec, "plain"

  # The key id to access your QingStor
  config :access_key_id, :validate => :string, :required => true

  # The key to access your QingStor
  config :secret_access_key, :validate => :string, :required => true

  # If specified, it would redirect to this host address.
  config :host, :validate => :string, :default => nil

  # It specifies the host port, please coordinate with config 'host'.
  config :port, :validate => :number, :default => 443

  # The name of the qingstor bucket
  config :bucket, :validate => :string, :required => true

  # The region of the QingStor bucket
  config :region, :validate => :string, :default => "pek3a"

  # If specified, it would only download the files with the specified prefix.
  config :prefix, :validate => :string, :default => nil

  # Set the directory where logstash store the tmp files before 
  # sending it to logstash, default directory in linux /tmp/logstash2qingstor
  config :tmpdir, :validate => :string, :default => File.join(Dir.tmpdir, "qingstor2logstash")

  # If this set to true, the remote file will be deleted after processed
  config :delete_remote_files, :validate => :boolean, :default => false
  
  # If this set to true, the file will backup to a local dir,
  # please make sure you can access to this dir.
  config :backup_local_dir, :validate => :string, :default => File.expand_path("~/")

  # If specified, the file will be upload to this bucket of the given region
  config :backup_bucket, :validate => :string, :default => nil

  # Specified the backup region in Qingstor.
  config :backup_region, :validate => ["pek3a", "sh1a"], :default => "pek3a"

  # This prefix, specially in qingstor, will add before the backup filename
  config :backup_prefix, :validate => :string, :default => ""
  
  # Use sincedb to record the last download time 
  config :sincedb_path, :validate => :string, :default => nil 
  
  # Set how frequently messages should be sent.
  # The default, `10`, means send a message every 10 seconds.
  config :interval, :validate => :number, :default => 10

  public
  def register

    if !@tmpdir.nil? && !directory_valid?(@tmpdir)
      raise LogStash::ConfigurationError, "Logstash must have the permissions to write to the temporary directory: #{@tmpdir}"
    end

    if !@backup_local_dir.nil? && !directory_valid?(@backup_local_dir)
      raise LogStash::ConfigurationError, "Logstash must have the permissions to write to the temporary directory: #{@backup_local_dir}"
    end


    @logger.info "Registering QingStor plugin", :bucket => @bucket, :region => @region
    
    @qs_config = QingStor::SDK::Config.init @access_key_id, @secret_access_key
    @qs_config.update({ host: @host, port: @port }) unless @host.nil?
    @qs_service = QingStor::SDK::Service.new @qs_config
    @qs_bucket = @qs_service.bucket @bucket, @region

    QingstorValidator.bucket_valid?(@qs_bucket)
    QingstorValidator.prefix_valid?(@backup_prefix) unless @backup_prefix.nil?

  end # def register

  def run(queue)
    @logger.info "starting processing"
    @current_thread = Thread.current
    Stud.interval(@interval) do
      process_files(queue)
    end
  end # def run

   
  def process_files(queue)
    objects = list_new_files

    # For each record in objects, it will be download and read 
    # into logstash. Then it will do deletion or backup job 
    # according to preset flags.
    objects.each do |key, time|
      process_log(queue, key)
      backup_to_bucket key unless @backup_bucket.nil?
      backup_to_local_dir unless @backup_local_dir.nil?
      @qs_bucket.delete_object key if @delete_remote_files
    end

    # if fetched nothing, just return
    return if objects.empty?
    _time = objects.values.max 
    sincedb.write(Time.at(_time))
  end

  private 
  def list_new_files
    objects = {}
    @logger.info "starting fetching objects"
    res = @qs_bucket.list_objects({'prefix' => @prefix})
    res[:keys].each do |log|
      next unless is_desired?(log[:key])
      next unless sincedb.newer?(log[:modified])
      objects[log[:key]] = log[:modified]
      @logger.info("QingStor input: Adding to object:", :key => log[:key])
    end
    return objects
  end

  def process_log(queue, key)
    # a global var, for the next possible upload and copy job 
    @tmp_file_path = File.join(@tmpdir, File.basename(key))

    File.open(@tmp_file_path, 'wb') do |logfile|
      logfile.write @qs_bucket.get_object(key)[:body]
    end
    process_local_log(queue, @tmp_file_path)
  end
 
  def backup_to_bucket(key)
    properties = {'bucket-name' => @backup_bucket, 'zone' => @backup_region}
    bucket = QingStor::SDK::Bucket.new @qs_config, properties
    
    if bucket.head[:status_code] != 200
      res = bucket.put
      if res[:status_code] != 201
        @logger.error("ERROR : cannot create the bucket ", res[:message])
        raise LogStash::ConfigurationError, "cannot create the bucket"
      end 
    end 
    
    md5_string = Digest::MD5.file(@tmp_file_path).to_s

    new_key = if @backup_prefix.end_with?('/') || @backup_prefix.empty?
                @backup_prefix + key 
              else 
                @backup_prefix + '/' + key 
              end 

    bucket.put_object new_key, { 
      'content_md5' => md5_string,
      'body' => File.open(@tmp_file_path)
    }
  end 
 
  def backup_to_local_dir
    FileUtils.mkdir_p @backup_local_dir unless File.exist? @backup_local_dir
    FileUtils.cp @tmp_file_path, @backup_local_dir
  end
 
  def process_local_log(queue, filename)
    read_file(filename) do |line|
      @codec.decode(line) do |event|
        decorate(event)
        queue << event
      end
    end
  end
   
  def read_file(filename, &block)
    if gzip?(filename)
      read_gzip_file(filename, block)
    else
      read_plain_file(filename, block)
    end
  end

  def read_gzip_file(filename, block)
    begin
      Zlib::GzipReader.open(filename) do |decoder|
        decoder.each_line { |line| block.call(line) }
      end
    rescue Zlib::Error, Zlib::GzipFile::Error => e 
      @logger.error("Gzip codec: Cannot uncompress the file", :filename => filename)
      raise e 
    end 
  end 
   
  def read_plain_file(filename, block)
    File.open(filename, 'rb') do |file|
      file.each(&block)
    end
  end

  def is_desired?(filename)
    return logger?(filename) || gzip?(filename)
  end
 
  def logger?(filename)
    return filename.end_with?('.log')
  end
 
  def gzip?(filename)
    return filename.end_with?('.gz')
  end
 
  def sincedb
    @sincedb ||= if @sincedb_path.nil?
                    @logger.info("Using default path for the sincedb", :filename => sincedb_file)
                    SinceDB::File.new(sincedb_file)
                 else
                    @logger.info("Using the provided sincedb_path")
                    SinceDB::File.new(@sincedb_path)
                 end
  end 
 
  def sincedb_file
    File.join(ENV["HOME"], ".sincedb_" + Digest::MD5.hexdigest("#{@bucket}+#{@prefix}"))
  end

  module SinceDB
    class File
      def initialize(file)
        @sincedb_path = file
      end

      def newer?(date)
        Time.at(date) > read 
      end 

      def read 
        if ::File.exist?(@sincedb_path)
          content = ::File.read(@sincedb_path).chomp.strip
          return content.empty? ? Time.new(0) : Time.parse(content)
        else 
          return Time.new(0)
        end
      end 

      def write(since = nil)
        since = Time.now() if since.nil?
        ::File.open(@sincedb_path, 'w') { |file| file.write(since.to_s) }
      end 
    end 
  end  

  public 
  def stop
   Stud.stop!(@current_thread) unless @current_thread.nil?
  end

  def directory_valid?(path)
    begin 
      FileUtils.mkdir_p(path) unless Dir.exist?(path)
      ::File.writable?(path)
    rescue 
      false 
    end 
  end 
end # class LogStash::Inputs::Qingstor
