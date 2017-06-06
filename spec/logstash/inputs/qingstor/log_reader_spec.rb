require 'logstash/devutils/rspec/spec_helper'
require 'logstash/inputs/qingstor/log_reader'
require 'tmpdir'

describe LogStash::Inputs::Qingstor::LogReader do
  subject(:log_reader) { described_class.new('/a/example/path') }

  let(:content) { 'may the code be with you!' }
  let(:plain_file_path) { File.join(Dir.tmpdir, 'plain.log') }
  let(:gzip_file_path) { File.join(Dir.tmpdir, 'gzip.gz') }
  let(:invalid_file_path) { File.join(Dir.tmpdir, 'invalid.ivd') }

  context 'when read plain file' do
    before do
      File.open(plain_file_path, 'w') do |f|
        f.write(content)
      end
    end

    it do
      log_reader.filepath = plain_file_path
      log_reader.read_file do |f|
        expect(f).to eq(content)
      end
    end
  end

  context 'when read gzip file' do
    before do
      Zlib::GzipWriter.open(gzip_file_path) do |gz|
        gz.write(content)
      end
    end

    it do
      log_reader.filepath = gzip_file_path
      log_reader.read_file do |f|
        expect(f).to eq(content)
      end
    end
  end

  context 'when valid format' do
    it { expect(log_reader.valid_format?(plain_file_path)).to be_truthy }
    it { expect(log_reader.valid_format?(gzip_file_path)).to be_truthy }
    it { expect(log_reader.valid_format?(invalid_file_path)).to be_falsey }
  end
end
