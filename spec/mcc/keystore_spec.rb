require 'spec_helper'
require 'mcc/keystore'

describe MCC::Keystore do

  let(:keystore) { MCC::Keystore.new }
  let(:mcc_root_dir) { "/mcc_root" }
  let(:mcc_keys_dir) { "/mcc_root/keys" }
  let(:mock_key_file) { double("key") }
  let(:key_file_name) { "/mcc_root/keys/mykey.pub" }

  before do
    allow(File).to receive(:expand_path).with("~/.mcc/keys/").and_return mcc_keys_dir
    allow(File).to receive(:expand_path).with('~/.mcc').and_return mcc_root_dir
    allow(File).to receive(:directory?).with("/mcc_root/keys/").and_return true
  end


  describe 'when created' do
    it 'creates the root keystore if it does not exist' do
      allow(File).to receive(:directory?).with("/mcc_root/keys/").and_return false
      expect(Dir).to receive(:mkdir).with("/mcc_root", 0700)
      expect(Dir).to receive(:mkdir).with("/mcc_root/keys/", 0700)
      keystore
    end

    it 'does not create the keystore if it already exists' do
      expect(Dir).to_not receive(:mkdir).with("/mcc_root", 0700)
      expect(Dir).to_not receive(:mkdir).with("/mcc_root/keys/", 0700)
      keystore
    end
  end

  describe 'adding a key' do
    it 'writes the key to the keystore if it does not exist' do
      allow(File).to receive(:file?).with(key_file_name).and_return false
      expect(File).to receive(:open).with(key_file_name, 'w+', 0600).and_return mock_key_file
      expect(mock_key_file).to receive(:write).with("ssh-rsa AABB\n")
      expect(mock_key_file).to receive(:close)
      keystore.add_key("mykey", "ssh-rsa AABB")
    end

    it 'raises an error if the key already exists' do
      allow(File).to receive(:file?).with(key_file_name).and_return true
      expect{keystore.add_key("mykey", "ssh-rsa AABB")}.to raise_error
    end
  end

  describe 'deleting a key' do
    it 'removes the key file' do
      expect(File).to receive(:delete).with key_file_name
      keystore.del_key("mykey")
    end
  end

  describe 'fetching a key' do
    it 'reads the stored key' do
      expect(File).to receive(:read).with(key_file_name).and_return "ssh-rsa AABB"
      expect(keystore.get_pub_key("mykey")).to eql "ssh-rsa AABB"
    end
  end

  describe 'listing all the keys' do
    it 'returns a list of valid public keys' do
      expect(Dir).to receive(:foreach).with(mcc_keys_dir + "/").and_return ["a.pub", "b", "c.pub"]
      expect(keystore.get_keys).to eql ["a", "c"]
    end
  end

  describe 'checking if a key exists' do
    it 'is true if the key is a file' do
      expect(File).to receive(:file?).with(key_file_name).and_return true
      expect(keystore.exists?("mykey")).to eql true
    end
    it 'is false if the key is not a file or does not exist' do
      expect(File).to receive(:file?).with(key_file_name).and_return false
      expect(keystore.exists?("mykey")).to eql false
    end
  end

end