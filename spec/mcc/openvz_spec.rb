require 'spec_helper'
require 'mcc/openvz'

describe MCC::OpenVZ do

  let(:openvz) { MCC::OpenVZ.new("1.1.1.1-1.1.1.20") }
  let(:template_dir_stdout) { "TEMPLATE = /images\n" }
  let(:template_dir_listing_stdout) { "ubuntu.tar.gz\ncentos.tar.gz\n" }
  let(:single_instance_stdout) { "101 1.1.1.1 running ubuntu instance1\n" }
  let(:all_instances_stdout) {
    "101 1.1.1.1 running ubuntu instance1\n" +
    "102 1.1.1.2 stopped centos instance2\n" +
    "103 1.1.1.3 running redhat instance3\n"
  }
  let(:running_instances_stdout) {
    "101 1.1.1.1 running ubuntu instance1\n" +
    "103 1.1.1.3 running redhat instance3\n"
  }
  let(:instance_types_stdout) {
    "ve-basic.conf-sample\n" +
    "ve-light.conf-sample\n" +
    "ve-vswap-1024m.conf-sample\n" +
    "ve-vswap-1g.conf-sample\n"
  }
  let(:instance1) {{
        :id => '101',
        :ip => '1.1.1.1',
        :status => "running",
        :ostemplate => "ubuntu",
        :name => "instance1"
    }}
  let(:instance2) {{
      :id => '102',
      :ip => '1.1.1.2',
      :status => "stopped",
      :ostemplate => "centos",
      :name => "instance2"
  }}
  let(:instance1) {{
      :id => '101',
      :ip => '1.1.1.1',
      :status => "running",
      :ostemplate => "ubuntu",
      :name => "instance1"
  }}
  let(:instance3) {{
      :id => '103',
      :ip => '1.1.1.3',
      :status => "running",
      :ostemplate => "redhat",
      :name => "instance3"
  }}


  describe 'listing instances' do
    it 'should return the instance the user requested' do
      expect(openvz).to receive(:'`').with("vzlist -H -o ctid,ip,status,ostemplate,name instance1").and_return single_instance_stdout
      expect(openvz.get_instances({'instance' => "instance1"})).to eql [ instance1 ]
    end
    it 'should return all running and stopped instances when all are requested' do
      expect(openvz).to receive(:'`').with("vzlist -a -H -o ctid,ip,status,ostemplate,name").and_return all_instances_stdout
      expect(openvz.get_instances( 'all' => true)).to eql [ instance1, instance2, instance3 ]
    end
    it 'should return all running instances by default' do
      expect(openvz).to receive(:'`').with("vzlist -H -o ctid,ip,status,ostemplate,name").and_return running_instances_stdout
      expect(openvz.get_instances).to eql [ instance1, instance3 ]
    end
  end

  describe 'listing images' do
    it 'returns a list all of images' do
      expect(openvz).to receive(:'`').with('grep -e "^TEMPLATE" /etc/vz/vz.conf').and_return template_dir_stdout
      expect(openvz).to receive(:'`').with('ls  /images/cache').and_return template_dir_listing_stdout
      expect(openvz.get_images).to eql ["ubuntu", "centos"]
    end
  end

  describe 'listing instance types' do
    it 'returns a list of instance types' do
      expect(openvz).to receive(:'`').with('ls /etc/vz/conf/ | grep -e "sample$"').and_return instance_types_stdout
      expect(openvz.get_instance_types).to eql ["basic", "light", "vswap-1024m", "vswap-1g"]
    end

  end

end