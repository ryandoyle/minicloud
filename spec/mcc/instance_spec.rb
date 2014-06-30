require 'spec_helper'
require 'mcc/instance'

describe MCC::Instance do

  let(:instance) { MCC::Instance.new(101) }

  def allow_vzlist(filter)
    allow(instance).to receive(:'`').with("vzlist -a -H -o #{filter} 101")
  end

  before do
    allow_vzlist("status").and_return "running\n"
    allow_vzlist("ip").and_return "192.168.1.50\n"
    allow_vzlist("ostemplate").and_return "centos-6-x86_64\n"
    allow_vzlist("name").and_return "foops1\n"



  end

  describe '#running?' do
    it 'is true if the container is running' do
      expect(instance.running?).to eql true
    end

    it 'is false if the container is not running' do
      allow_vzlist("status").and_return "stopped\n"
      expect(instance.running?).to eql false
    end
  end

  describe '#status' do
    it 'is :stopped if the container is stopped' do
      allow_vzlist("status").and_return "stopped\n"
      expect(instance.status).to eql :stopped
    end
  end

  describe '#ip' do
    it 'returns the IP address of the container' do
      expect(instance.ip).to eql "192.168.1.50"
    end
  end

  describe '#template' do
    it 'returns the template the instance is based off' do
      expect(instance.template).to eql "centos-6-x86_64"
    end
  end

  describe '#name' do
    it 'returns the name of the instance' do
      expect(instance.name).to eql "foops1"

    end
  end

  describe 'to_h' do
    it 'returns a hash of the instance' do
      expect(instance.to_h).to eql :id => 101, :ip => "192.168.1.50", :status => :running, :ostemplate => "centos-6-x86_64", :name => "foops1"
    end

  end

end