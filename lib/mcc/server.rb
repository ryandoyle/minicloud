require 'xmlrpc/server'

require 'mcc/images'

module MCC
  class Server
  
    def initialize(port, listen, iprange, log)
      @port = port
      @listen = listen
      @iprange = iprange
      @logtype = log
      $ip_store = Array.new
      $ctid_store = Array.new
      @images = Images.new
    end
    
    def run()
      s = XMLRPC::Server.new(@port, @listen, 10, @logtype)
      s.add_handler("openvz", MCC::OpenVZ.new(@iprange, @images, @logtype))
      s.serve
    end
  
  end
end

