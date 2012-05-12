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
			res = @rpc.call("openvz.get_instances", opts)
			return res
		end
		
		def get_images()
			res = @rpc.call("openvz.get_images")
			return res
		end
		
		def get_instance_types()
			res = @rpc.call("openvz.get_instance_types")
			return res
		end
		
		def run_instance(template, type, pubkey, name)
			res = @rpc.call("openvz.run_instance", template, type, pubkey, name)
			return res
		end
		
		def destroy_instance(id)
			res = @rpc.call("openvz.destroy_instance", id)
			return res
		end  
	end
end
