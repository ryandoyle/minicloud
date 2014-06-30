require 'spec_helper'

require 'mcc/instances'

describe MCC::Instances do

  let(:instances) { MCC::Instances.new }
  let(:instances_stdout) { "       500\n" +
                           "       501\n"
  }
  let(:instance1) { double("instance1") }
  let(:instance2) { double("instance2") }

  before do
    allow(instances).to receive(:'`').with("vzlist -a -H -o ctid").and_return instances_stdout
    allow(MCC::Instance).to receive(:new).with('500').and_return instance1
    allow(MCC::Instance).to receive(:new).with('501').and_return instance2
  end

  it 'should return all instances' do
    expect(instances.all).to eql [instance1, instance2]
  end

  it 'should return running instances' do
    allow(instance1).to receive(:running?).and_return true
    allow(instance2).to receive(:running?).and_return false
    expect(instances.running).to eql [instance1]
  end
end