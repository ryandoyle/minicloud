require 'spec_helper'

require 'mcc/instance_types'

describe MCC::InstanceTypes do

  let(:instance_types) { MCC::InstanceTypes.new }
  let(:instance_types_stdout) { "ve-basic.conf-sample\nve-light.conf-sample\n" }

  before do
    allow(instance_types).to receive(:'`').with('ls /etc/vz/conf/ | grep -e "sample$"').and_return instance_types_stdout
  end

  it 'returns a list of instance types' do
    expect(instance_types.all).to eql [ "basic", "light" ]
  end

  it 'has enumerable traits' do
    expect(instance_types.include? "basic").to eql true
  end



end