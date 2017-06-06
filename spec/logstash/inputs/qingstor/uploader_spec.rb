require 'logstash/devutils/rspec/spec_helper'
require 'logstash/inputs/qingstor/uploader'
require 'qingstor/sdk'
require 'stud/temporary'
require_relative '../qs_access_helper'

describe LogStash::Inputs::Qingstor::Uploader do
  let(:bucket) { qs_init_bucket }
  let(:new_bucket) { qs_init_bucket }
  let(:key) { 'foobar' }
  let(:file) { Stud::Temporary.file }
  let(:filepath) { file.path }
  let(:logger) { spy(:logger) }

  context 'when upload file' do
    let(:prefix) { '' }

    after do
      delete_remote_file(prefix + key)
    end

    it do
      uploader = described_class.new(bucket, prefix, logger)
      uploader.upload(key, filepath)
      expect(list_remote_file.size).to eq(1)
    end
  end

  context 'when upload file with a prefix' do
    let(:prefix) { 'a/prefix/' }

    after do
      delete_remote_file(prefix + key)
    end

    it do
      uploader = described_class.new(bucket, prefix, logger)
      uploader.upload(key, filepath)
      expect(list_remote_file.size).to eq(1)
    end
  end
end
