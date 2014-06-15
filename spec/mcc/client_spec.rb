require 'spec_helper'
require 'mcc/client'

describe MCC::Client do

  let(:server) { "localhost:12345" }
  let(:client) { MCC::Client.new(server) }
  let(:xmlclient) { double("xml_client") }
  let(:mock_instance) { {
      :id => "101",
      :ip => "1.2.3.4",
      :status => "running",
      :ostemplate => "template",
      :name => "host"}
  }
  let(:mock_images) { ["ubuntu", "debian"] }
  let(:mock_instance_types) { ["small", "large"] }
  let(:mock_run_instance) { {:id => "101", :ip => "1.2.3.4"} }

  before do
    allow(XMLRPC::Client).to receive(:new).and_return xmlclient
  end

  it 'should create an RPC connection to the server' do
    expect(XMLRPC::Client).to receive(:new).with("localhost", "/", "12345")
    MCC::Client.new(server)
  end

  it 'should remotely get instances' do
    expect(xmlclient).to receive(:call).with("openvz.get_instances", {}).and_return mock_instance
    expect(client.get_instances).to be(mock_instance)
  end

  it 'should remotely get images' do
    expect(xmlclient).to receive(:call).with("openvz.get_images").and_return mock_images
    expect(client.get_images).to be(mock_images)
  end

  it 'should remotely get instance types' do
    expect(xmlclient).to receive(:call).with("openvz.get_instance_types").and_return mock_instance_types
    expect(client.get_instance_types).to be(mock_instance_types)
  end

  it 'should remotely run an instance' do
    expect(xmlclient).to receive(:call).with("openvz.run_instance", "ubuntu", "small", "my_key", "my_name").and_return mock_run_instance
    expect(client.run_instance("ubuntu", "small", "my_key", "my_name")).to be(mock_run_instance)
  end

  it 'should remotely destroy an instance' do
    expect(xmlclient).to receive(:call).with("openvz.destroy_instance", "101")
    client.destroy_instance("101")
  end

end