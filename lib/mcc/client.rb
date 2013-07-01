require 'xmlrpc/client'

module MCC
  class Client
  
    def initialize(server)
      begin
        host = server.split(":")
        @rpc = XMLRPC::Client.new(host[0], "/", host[1])
      rescue
        raise "MCC_SERVER environment variable not set"
      end
    end
    
    def get_instances(opts = {})
      @rpc.call("openvz.get_instances", opts)
    end
    
    def get_images()
      @rpc.call("openvz.get_images")
    end
    
    def get_instance_types()
      @rpc.call("openvz.get_instance_types")
    end
    
    def run_instance(template, type, pubkey, name)
      @rpc.call("openvz.run_instance", template, type, pubkey, name)
    end
    
    def destroy_instance(id)
      @rpc.call("openvz.destroy_instance", id)
    end  
  end
end
