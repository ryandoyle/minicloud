module VZRuby
	# Source the client and server libs
	libs = ["server/server", "client/client"]
	libs.each do |lib|
		require File.expand_path(
			File.join(
				File.dirname(
					File.expand_path(
						File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
					)
				), lib
			)
		)
	
	end
end
