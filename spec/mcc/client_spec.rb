require 'spec_helper'
require 'mcc/client'

describe MCC::Client do

  let(:server) { "localhost:12345" }

  it 'should create an RPC connection to the server' do
    expect(XMLRPC::Client).to receive(:new).with("localhost", "/", "12345")
    MCC::Client.new(server)
  end

end