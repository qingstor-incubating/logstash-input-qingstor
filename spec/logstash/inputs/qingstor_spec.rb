require 'logstash/devutils/rspec/spec_helper'
require 'logstash/inputs/qingstor'
require_relative './qs_access_helper'
require 'tmpdir'

describe LogStash::Inputs::Qingstor do
  before do
    Thread.abort_on_exception = true

    upload_file('../../fixtures/logstash.log', 'log3.log')
    upload_file('../../fixtures/logstash.log.gz', 'log3.log.gz')
  end

  after do
    delete_remote_file 'log3.log'
    delete_remote_file 'log3.log.gz'
  end

  let(:config) do
    { 'access_key_id' => ENV['access_key_id'],
      'secret_access_key' => ENV['secret_access_key'],
      'bucket' => ENV['bucket'],
      'region' => ENV['region'] }
  end

  let(:key1) { 'log3.log' }
  let(:key2) { 'log3.log.gz' }
  let(:backup) { 'evamax' }
  let(:local_backup_dir) { File.join(Dir.tmpdir, backup) }

  context 'when at the local' do
    it 'backup to local dir' do
      fetch_events(config.merge('backup_local_dir' => local_backup_dir))
      expect(File.exist?(File.join(local_backup_dir, key1))).to be_truthy
      expect(File.exist?(File.join(local_backup_dir, key2))).to be_truthy
    end

    after do
      FileUtils.rm_r(File.join(local_backup_dir, key1))
      FileUtils.rm_r(File.join(local_backup_dir, key2))
    end
  end

  context 'when backup to the remote end' do
    it do
      fetch_events(config.merge('backup_bucket' => backup))
      expect(list_remote_file(backup).size).to eq(2)
    end

    after do
      clean_and_delete_bucket(backup)
    end
  end

  context 'when test host redirection' do
    it 'redirect without a port number' do
      expect { fetch_events(config.merge('host' => 'qingstor.dev')) }
        .to raise_error(Net::HTTP::Persistent::Error)
    end

    it 'redirect with a port number' do
      new_config = config.merge('host' => 'qingstor.dev', 'port' => 444)
      expect { fetch_events(new_config) }
        .to raise_error(Net::HTTP::Persistent::Error)
    end
  end

  context 'when test with various config values' do
    it do
      config['access_key_id'] = 'wrongid'
      expect { described_class.new(config).register }
        .to raise_error(LogStash::ConfigurationError)
    end

    it do
      config['secret_access_key'] = 'wrongaccesskey'
      expect { described_class.new(config).register }
        .to raise_error(LogStash::ConfigurationError)
    end

    it do
      config['bucket'] = 'wrongbucket'
      expect { described_class.new(config).register }
        .to raise_error(LogStash::ConfigurationError)
    end

    it do
      config['region'] = 'wrongregion'
      expect { described_class.new(config).register }
        .to raise_error(LogStash::ConfigurationError)
    end

    it do
      config.delete('region')
      expect(described_class.new(config).register).to be_truthy
    end
  end
end
