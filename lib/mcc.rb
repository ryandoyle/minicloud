module MCC
	# Source the client and server libs
	libs = ["client", "server", "openvz", "keystore"]
	libs.each do |lib|
		require File.expand_path(
			File.join(
				File.dirname(
					File.expand_path(
						File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
					)
				), "mcc/"+lib
			)
		)
	
	end
end

