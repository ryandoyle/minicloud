module MCC
  class Keystore
    
    KS = File.expand_path('~/.mcc/keys/') + '/'
    
    def initialize()
      # Check if the .mcc/keys directory exists and create it
      if ! File.directory?(KS)
        # Can't find a way to make the parent
        Dir.mkdir(File.expand_path('~/.mcc'), 0700)
        Dir.mkdir(KS, 0700)
      end
    end
    
    def add_key(keyname, pub)
      raise "Key " + keyname + " already exists" if File.file?(KS + keyname + ".pub")
      f = File.open(KS + keyname + ".pub", 'w+', 0600)
      f.write(pub + "\n")
      f.close
    end
    
    def del_key(keyname)
      File.delete(KS + keyname + ".pub")
    end
    
    def get_pub_key(keyname)
      File.open(KS + keyname + ".pub", 'r') do |f|
        return f.read
      end
    end
    
    def get_keys()
      Dir.foreach(KS).map do |f|
        f.gsub('.pub', '') if f.include?('.pub')
      end.compact
    end
    
    def exists?(keyname)
      return File.file?(KS + keyname + ".pub")
    end
  
  end
end
