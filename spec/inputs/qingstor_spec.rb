# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/qingstor"
require_relative "./qs_access_helper"
require "tmpdir"

describe LogStash::Inputs::Qingstor do

  before do 
    Thread.abort_on_exception = true

    upload_file("../fixtures/logstash.log", "log3.log")
    upload_file("../fixtures/logstash.log.gz", "log3.log.gz")
  end

  after do 
    delete_remote_file "log3.log"    
    delete_remote_file "log3.log.gz"
  end

  let(:config) { { 
      "access_key_id" => ENV['access_key_id'],
      "secret_access_key" => ENV['secret_access_key'],
      "bucket" => ENV['bucket'],
      "region" => ENV['region']
  } }
  let(:key1) { "log3.log" }
  let(:key2) { "log3.log.gz" }
  let(:backup) { "logstash-backup" }
  let(:local_backup_dir) { File.join(Dir.tmpdir, backup) }

  context "local backup" do 
    it "backup to local dir" do 
      fetch_events(config.merge({"backup_local_dir" => local_backup_dir }))
      expect(File.exists?(File.join(local_backup_dir, key1))).to be_truthy
      expect(File.exists?(File.join(local_backup_dir, key2))).to be_truthy
    end 
    
    after do 
      FileUtils.rm_r(File.join(local_backup_dir, key1))
      FileUtils.rm_r(File.join(local_backup_dir, key2))
    end 
  end 

  context "remote backup" do 
    it "backup to another bucket" do 
      fetch_events(config.merge({"backup_bucket" => backup}))
      expect(list_remote_file(backup).size).to eq(2)
    end 

    after do 
      delete_bucket(backup)
    end 
  end 

end
