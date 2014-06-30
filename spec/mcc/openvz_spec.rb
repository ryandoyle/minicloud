require 'spec_helper'
require 'mcc/openvz'

describe MCC::OpenVZ do

  let(:images) { double("Images") }
  let(:openvz) { MCC::OpenVZ.new("1.1.1.1-1.1.1.20", images) }
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

  let(:instances_double) { [instances_double1, instances_double2] }
  let(:instances_double1) { double("instance1", :container_id => '101', :to_h => {
      :id=>"101",
      :ip=>"1.1.1.1",
      :status=>"running",
      :ostemplate=>"ubuntu",
      :name=>"instance1"
    })
  }
  let(:instances_double2) { double("instance2", :container_id => '102', :to_h => {
      :id => '102',
      :ip => '1.1.1.2',
      :status => "stopped",
      :ostemplate => "centos",
      :name => "instance2"
    })
  }


  def expect_shell_command(command)
    expect(openvz).to receive(:'`').with(command)
  end

  describe 'listing instances' do
    before do
      allow(MCC::Instances).to receive(:new).and_return instances_double
      allow(instances_double).to receive(:all).and_return instances_double
    end
    it 'should return the instance the user requested' do
      expect(openvz.get_instances({'instance' => "101"})).to eql [ instance1 ]
    end
    it 'should return all running and stopped instances when all are requested' do
      expect(openvz.get_instances( 'all' => true)).to eql [ instance1, instance2  ]
    end
    it 'should return all running instances by default' do
      allow(instances_double).to receive(:running).and_return [ instances_double1 ]
      expect(openvz.get_instances).to eql [ instance1 ]
    end
  end

  describe 'listing images' do
    it 'returns a list all of images' do
      allow(images).to receive(:all).and_return ["ubuntu", "centos"]
      expect(openvz.get_images).to eql ["ubuntu", "centos"]
    end
  end

  describe 'listing instance types' do
    it 'returns a list of instance types' do
      expect_shell_command('ls /etc/vz/conf/ | grep -e "sample$"').and_return instance_types_stdout
      expect(openvz.get_instance_types).to eql ["basic", "light", "vswap-1024m", "vswap-1g"]
    end
  end

  describe 'running an instance' do

    before do
      $ip_store = Array.new
      $ctid_store = Array.new
    end

    # TODO: Add more tests around IP/CTID collision detection

    it 'should return the container ID and IP address of what will be created' do
      allow(openvz).to receive(:get_instance_types).and_return ['basic']
      allow(openvz).to receive(:get_images).and_return ['ubuntu']
      allow(openvz).to receive(:find_ip).and_return '1.2.3.4'
      allow(openvz).to receive(:find_ctid).and_return 191
      allow(images).to receive(:include?).and_return true

      # Calls inside Thread.new
      expect_shell_command "vzctl create 191 --ostemplate ubuntu --config basic --ipadd 1.2.3.4 --hostname mcc-id-191.localdomain --name \"\""
      expect_shell_command "vzctl start 191"
      expect_shell_command "vzctl exec 191 'mkdir /root/.ssh'"
      expect_shell_command "vzctl exec 191 'chmod 700 /root/.ssh'"
      expect_shell_command "vzctl exec 191 'echo \"\" >> /root/.ssh/authorized_keys'"
      expect_shell_command "vzctl exec 191 'chmod 600 /root/.ssh/authorized_keys'"
      expect_shell_command("cat /etc/resolv.conf").and_return "nameserver 1.1.1.1"
      expect_shell_command "vzctl exec 191 'echo \"nameserver 1.1.1.1\" >> /etc/resolv.conf'"


      expect(Thread).to receive(:new).and_yield
      expect(openvz.run_instance('ubuntu')).to eql :id => 191, :ip => '1.2.3.4'
    end

  end

  describe 'destroying an instance' do
    it 'destroys the instance if it is a valid container ID' do
      allow(openvz).to receive(:get_instances).and_return [instance1,instance2]

      expect_shell_command 'vzctl stop 101'
      expect_shell_command 'vzctl destroy 101'

      expect(Thread).to receive(:new).and_yield
      openvz.destroy_instance 101
    end

    it 'raises an error if the container ID is not valid' do
      allow(openvz).to receive(:get_instances).and_return [instance1]
      expect{openvz.destroy_instance(999)}.to raise_error
    end
  end

end