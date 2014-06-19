require 'spec_helper'
require 'mcc/openvz'

describe MCC::OpenVZ do

  let(:openvz) { MCC::OpenVZ.new("1.1.1.1-1.1.1.20") }
  let(:single_instance) { "101 1.1.1.1 running ubuntu someinstance\n" }


  describe 'listing instances' do
    it 'should return the instance the user requested' do
      expect(openvz).to receive(:'`').with("vzlist -H -o ctid,ip,status,ostemplate,name someinstance").and_return single_instance
      expect(openvz.get_instances({'instance' => "someinstance"})).to eql [
        { :id => '101', :ip => '1.1.1.1', :status => "running", :ostemplate => "ubuntu", :name => "someinstance"}
      ]
    end

  end

end