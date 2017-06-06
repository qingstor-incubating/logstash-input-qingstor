require 'logstash/devutils/rspec/spec_helper'
require 'logstash/inputs/qingstor/sincedb'
require 'tmpdir'

describe LogStash::Inputs::Qingstor::SinceDB do
  subject(:sincedb) { described_class.new(sincedb_path) }

  let(:sincedb_path) { File.join(Dir.tmpdir, 'log_tmp_dir/log_tmp.log') }

  context 'when run at first time' do
    before do
      File.delete(sincedb_path) if File.exist?(sincedb_path)
    end

    it { expect(sincedb.read).to eq(Time.new(0)) }
    it { expect(sincedb.newer?(Time.now)).to be_truthy }
  end

  context 'when write the record' do
    it do
      time = Time.now
      sincedb.write(time)
      content = File.read(sincedb_path).chomp.strip
      expect(content).to eq(time.to_s)
    end
  end
end
