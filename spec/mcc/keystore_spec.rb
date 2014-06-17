require 'spec_helper'
require 'mcc/keystore'

describe MCC::Keystore do

  #let(:keystore) { MCC::Keystore.new }

  before do
    allow(File).to receive(:expand_path).with("~/.mcc/keys/").and_return("/mcc_root/keys")
    allow(File).to receive(:expand_path).with('~/.mcc').and_return("/mcc_root")
  end


  describe 'when created' do
    it 'creates the root keystore if it does not exist' do
      allow(File).to receive(:directory?).with("/mcc_root/keys/").and_return false
      expect(Dir).to receive(:mkdir).with("/mcc_root", 0700)
      expect(Dir).to receive(:mkdir).with("/mcc_root/keys/", 0700)
      MCC::Keystore.new
    end

    it 'does not create the keystore if it already exists' do
      allow(File).to receive(:directory?).with("/mcc_root/keys/").and_return true
      expect(Dir).to_not receive(:mkdir).with("/mcc_root", 0700)
      expect(Dir).to_not receive(:mkdir).with("/mcc_root/keys/", 0700)
      MCC::Keystore.new
    end
  end

end