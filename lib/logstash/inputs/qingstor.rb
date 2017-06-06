require 'logstash/inputs/base'
require 'logstash/namespace'
require 'stud/interval'
require 'qingstor/sdk'
require 'fileutils'
require 'tmpdir'

# Logstash Inputs Plugin for QingStor
class LogStash::Inputs::Qingstor < LogStash::Inputs::Base
  require 'logstash/inputs/qingstor/qingstor_validator'
  require 'logstash/inputs/qingstor/sincedb'
  require 'logstash/inputs/qingstor/uploader'
  require 'logstash/inputs/qingstor/log_reader'

  include QingstorValidator

  config_name 'qingstor'

  default :codec, 'plain'

  # The key id to access your QingStor
  config :access_key_id, :validate => :string, :required => true

  # The key to access your QingStor
  config :secret_access_key, :validate => :string, :required => true

  # If specified, it would redirect to this host address.
  config :host, :validate => :string, :default => nil

  # It specifies the host port, please coordinate with config 'host'.
  config :port, :validate => :number, :default => 443

  # The name of the QingStor bucket
  config :bucket, :validate => :string, :required => true

  # The region of the QingStor bucket
  config :region, :validate => :string, :default => 'pek3a'

  # If specified, it would only download the files with the specified prefix.
  config :prefix, :validate => :string, :default => nil

  # Set the directory where logstash store the tmp files before
  # sending it to logstash, default directory in linux /tmp/qingstor2logstash
  config :tmpdir, :validate => :string,
                  :default => File.join(Dir.tmpdir, 'qingstor2logstash')

  # If this set to true, the remote file will be deleted after processed
  config :delete_remote_files, :validate => :boolean, :default => false

  # If this set to a valid path, the file will be backup under a local path,
  # please make sure you can access to this dir.
  config :backup_local_dir, :validate => :string, :default => nil

  # If specified, the file will be upload to this bucket of the given region
  config :backup_bucket, :validate => :string, :default => nil

  # Specified the backup region in QingStor.
  config :backup_region, :validate => :string, :default => 'pek3a'

  # This prefix, specially in QingStor, will add before the backup filename
  config :backup_prefix, :validate => :string, :default => ''

  # Use sincedb to record the last download time
  config :sincedb_path, :validate => :string, :default => nil

  # Set how frequently messages should be sent.
  # The default, `10`, means send a message every 10 seconds.
  config :interval, :validate => :number, :default => 10

  def register
    check_settings
    @logger.info('Registering QingStor plugin', :bucket => @bucket,
                                                :region => @region)
    @qs_bucket = qs_bucket(@bucket, @region)
    bucket_valid?(@qs_bucket)
    unless @backup_bucket.nil?
      backup_bucket = qs_bucket(@backup_bucket, @backup_region)
      prefix_valid?(@backup_prefix) unless @backup_prefix.nil?
      @uploader = Uploader.new(backup_bucket, @backup_prefix, @logger)
    end
    @log_reader = LogReader.new('/a/tmp/path')
  end # def register

  def run(queue)
    @logger.info('starting processing')
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
    objects.each do |key, _|
      process_log(queue, key)
      @uploader.upload_async(key, @tmp_file_path) unless @backup_bucket.nil?
      backup_to_local_dir unless @backup_local_dir.nil?
      @qs_bucket.delete_object(key) if @delete_remote_files
    end

    # if fetched nothing, just return
    return if objects.empty?
    tmp_time = objects.values.max
    sincedb.write(Time.at(tmp_time))
  end

  def check_settings
    unless directory_valid?(@tmpdir)
      raise(LogStash::ConfigurationError, 'ERROR: no permissions to access'\
          + '#{@tmpdir}')
    end
    unless @backup_local_dir.nil? ||
           directory_valid?(@backup_local_dir)
      raise(LogStash::ConfigurationError, 'ERROR: no permissions to access'\
          + '#{@backup_local_dir}')
    end
  end

  def stop
    Stud.stop!(@current_thread) unless @current_thread.nil?
  end

  def directory_valid?(path)
    FileUtils.mkdir_p(path) unless Dir.exist?(path)
    ::File.writable?(path)
  rescue
    false
  end

  private

  def qs_bucket(bucket, region)
    config = QingStor::SDK::Config.init(@access_key_id, @secret_access_key)
    config.update(:host => @host, :port => @port) unless @host.nil?
    service = QingStor::SDK::Service.new(config)
    service.bucket(bucket, region)
  end

  def list_new_files
    objects = {}
    @logger.info('starting fetching objects')
    res = @qs_bucket.list_objects('prefix' => @prefix)
    res[:keys].each do |log|
      next unless @log_reader.valid_format?(log[:key])
      next unless sincedb.newer?(log[:modified])
      objects[log[:key]] = log[:modified]
      @logger.info('QingStor input: Adding to objects:', :key => log[:key])
    end
    objects
  end

  def process_log(queue, key)
    # a global var, for the next possible upload and copy job
    @tmp_file_path = File.join(@tmpdir, File.basename(key))
    File.open(@tmp_file_path, 'wb') do |logfile|
      logfile.write(@qs_bucket.get_object(key)[:body])
    end
    process_local_log(queue, @tmp_file_path)
  end

  def backup_to_local_dir
    FileUtils.mkdir_p @backup_local_dir unless File.exist? @backup_local_dir
    FileUtils.cp @tmp_file_path, @backup_local_dir
  end

  def process_local_log(queue, filename)
    @log_reader.filepath = filename
    @log_reader.read_file do |line|
      @codec.decode(line) do |event|
        decorate(event)
        queue << event
      end
    end
  end

  def sincedb
    @sincedb ||= if @sincedb_path.nil?
                   @logger.info('Using default path for the sincedb',
                                :filename => sincedb_file)
                   SinceDB.new(sincedb_file)
                 else
                   @logger.info('Using the provided sincedb_path')
                   SinceDB.new(@sincedb_path)
                 end
  end

  def sincedb_file
    File.join(ENV['HOME'],
              '.sincedb_' + Digest::MD5.hexdigest('#{@bucket}+#{@prefix}'))
  end
end # class LogStash::Inputs::Qingstor
