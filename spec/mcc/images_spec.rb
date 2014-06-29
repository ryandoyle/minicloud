require 'spec_helper'

require 'mcc/images'

describe MCC::Images do

  let(:image) { MCC::Images.new }

  before do
    allow(image).to receive(:'`').with('grep -e "^TEMPLATE" /etc/vz/vz.conf').and_return('TEMPLATE=/vz/template')
    allow(image).to receive(:'`').with('ls /vz/template/cache').and_return "centos-6-x86_64.tar.gz\nubuntu-14.04-x86_64.tar.gz\n"
  end

  it 'returns a list of images' do
    expect(image.all).to eql ['centos-6-x86_64', 'ubuntu-14.04-x86_64']
  end

  it 'has enumerable traits' do
    expect(image.include? 'centos-6-x86_64').to eql true
  end


end