# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/qingstor"

describe LogStash::Inputs::Qingstor do
  let(:config) { { 
      "access_key_id" => ENV['access_key_id'],
      "secret_access_key" => ENV['secret_access_key'],
      "bucket" => ENV['bucket'],
      "region" => ENV['region']
  } }
  
  it "raise error if it has incorrect key id or access key" do
    config["access_key_id"] = "wrongid"
    expect{ described_class.new(config).register }.to raise_error(LogStash::ConfigurationError)
  end

  it "raise error if it has incorrect key id or access key" do
    config["secret_access_key"] = "wrongaccesskey"
    expect{ described_class.new(config).register }.to raise_error(LogStash::ConfigurationError)
  end

  it "raise error if it has incorrect bucket/region name" do
    config["bucket"] = "wrongbucket"
    expect{ described_class.new(config).register }.to raise_error(LogStash::ConfigurationError)
  end

  it "raise error if it has incorrect bucket/region name" do
    config["region"] = "wrongregion"
    expect{ described_class.new(config).register }.to raise_error(LogStash::ConfigurationError)
  end

  it "use default region if it is not set" do 
    config.delete("region")
    expect(described_class.new(config).register ).to be_truthy
  end
end 