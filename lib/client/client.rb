require 'xmlrpc/client'

module VZRuby
	class Client
	
		def initialize(vzrserv)
			@rpc = XMLRPC::Client.new2(vzrserv)
		end
		
		def get_instances()
			@rpc.call("get_instances")
		end
	end
end
