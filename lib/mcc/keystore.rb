module MCC
  class Keystore


    def initialize()
      @keystore_root = File.expand_path('~/.mcc/keys/') + '/'
      # Check if the .mcc/keys directory exists and create it
      unless File.directory?(@keystore_root)
        # Can't find a way to make the parent
        Dir.mkdir(File.expand_path('~/.mcc'), 0700)
        Dir.mkdir(@keystore_root, 0700)
      end
    end
    
    def add_key(keyname, pub)
      raise "Key " + keyname + " already exists" if File.file?(KS + keyname + ".pub")
      f = File.open(@keystore_root + keyname + ".pub", 'w+', 0600)
      f.write(pub + "\n")
      f.close
    end
    
    def del_key(keyname)
      File.delete(@keystore_root + keyname + ".pub")
    end
    
    def get_pub_key(keyname)
      File.read(@keystore_root + keyname + ".pub")
    end
    
    def get_keys()
      Dir.foreach(@keystore_root).map do |f|
        f.gsub('.pub', '') if f.include?('.pub')
      end.compact
    end
    
    def exists?(keyname)
      File.file?(@keystore_root + keyname + ".pub")
    end
  
  end
end
