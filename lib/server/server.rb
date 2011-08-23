module VZRuby
	class Server
	
		def initialize()
			
		end
		
		# Get an array of OpenVZ instances
		def get_instances()
			ret_arr = Array.new
			res = `vzlist -H -o ctid,ip,status,ostemplate`
			# Process each line of the output
			res.each_line do |line|
				line.chomp!
				line.lstrip!
				e = line.split(' ')
				# Push each instance on the array we'll return
				ret_arr.push({:id => e[0], :ip => e[1], :status => e[2],:ostemplate => [3]})
			end
			return ret_arr
		end
	
	end
end
