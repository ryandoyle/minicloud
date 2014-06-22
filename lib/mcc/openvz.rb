require 'ipaddr'
require 'logger'
require 'thread'
module MCC
    class OpenVZ
  
    def initialize(iprange, log = STDOUT)
      # Split the IP range
      ip = iprange.split('-')
      @ip_start = ip[0]
      @ip_end = ip[1]
      # Logging, default to STDOUT, otherwise log file
      @log = Logger.new(log)
      @log.level = Logger::DEBUG
      
    end
    
    # Get an array of OpenVZ instances
    def get_instances(params = {})
      @log.debug "get_instances() called"
      ret_arr = Array.new
      if params['instance']
        @log.debug "get_instances() Specific instance #{params['instance']} requested."
        res = `vzlist -H -o ctid,ip,status,ostemplate,name #{params['instance']}`
      elsif params['all']
        @log.debug "get_instances() All running _and_ stopped instances requested"
        res = `vzlist -a -H -o ctid,ip,status,ostemplate,name`
      else
        @log.debug "get_instances() All running instances requested"
        res = `vzlist -H -o ctid,ip,status,ostemplate,name`
      end
      # Process each line of the output
      res.each_line do |line|
        line.chomp!
        line.lstrip!
        e = line.split(' ')
        # Push each instance on the array we'll return
        @log.debug "get_instances() Found instance ctid:" + e[0] + " ip:" + e[1] + " status:" + e[2] + " ostemplate:" + e[3] + " name:" + e[4]
        ret_arr.push({:id => e[0], :ip => e[1], :status => e[2],:ostemplate => e[3],:name => e[4]})
      end
      return ret_arr
    end
    
    def get_images()
      ret_arr = Array.new
      @log.info("Getting list of images")
      @log.debug "get_images() called. Looking in /etc/vz/vz.conf for TEMPLATE param"
      # Find out where the templates are stored
      template_conf = `grep -e "^TEMPLATE" /etc/vz/vz.conf`
      template_dir = template_conf.chomp!.split("=")
      @log.debug "get_images() Found template directory: " + template_dir[1] 
      @log.debug "get_images() Assuming full path: " + template_dir[1] + "/cache"
      templates = `ls #{template_dir[1]}/cache`
      # Process each line
      templates.each_line do |tpl|
        @log.debug "get_images() Found template: " + template_dir[1] + "/cache/" + tpl 
        # Push each template onto the ret array and kill off the tar.gz extension
        ret_arr.push(tpl.chomp!.gsub(/\.tar\.gz/, ''))
      end
      return ret_arr
    end
    
    def get_instance_types()
      @log.info "Getting list of instance types"
      ret_arr = Array.new
      @log.debug "get_instance_types() Looking in /etc/vz/conf/"
      types = `ls /etc/vz/conf/ | grep -e "sample$"`
      types.each_line do |type|
        @log.debug "get_instance_types() Found " + type.chomp!
        begin
          #ret_arr.push(type)
          ret_arr.push(type.gsub(/\.conf-sample$/, '').gsub(/^ve-/, ''))
        rescue 
          @log.debug "get_instance_types() Exception raised when pushing to the array. Skipping."
        end
      end
      return ret_arr
    end
    
    def run_instance(template, type = 'basic', pubkey = '', name = '')
      # Check if the template type exist first
      unless get_instance_types.include?(type)
        @log.err "run_instance() Instance type " + type + " not found"
        raise "Instance type " + type + " not found"
      end
      # Check if the image exists
      unless get_images.include?(template)
        @log.err "run_instance() Image template " + template + " not found!"
        raise "Image template " + template + " not found!"
      end
      @log.info "Running instance " + template
      
      ip = find_ip()
      @log.debug "run_instance() Reserving IP #{ip} and pushing to the temp store"
      $ip_store.push(IPAddr.new(ip, Socket::AF_INET).to_i)
      
      ctid = find_ctid()
      @log.debug "run_instance() Reserving CTID #{ctid} and pushing to the temp store"
      $ctid_store.push(ctid)
      
      @log.debug "run_instance() Creating with template:" + template + ", type: " + type 
      
      # Create it and start
      @log.debug "run_instance() Threading creation"
      
      t1 = Thread.new do
        @log.debug "run_instance(thread) Running: vzctl create #{ctid} --ostemplate #{template} --config #{type} --ipadd #{ip} --hostname mcc-id-#{ctid}.localdomain --name \"#{name}\""
        create = `vzctl create #{ctid} --ostemplate #{template} --config #{type} --ipadd #{ip} --hostname mcc-id-#{ctid}.localdomain --name "#{name}"`
        @log.debug "run_instance(thread) Running: vzctl start #{ctid}"
        start = `vzctl start #{ctid}`
        # Inject the key
        @log.debug "run_instance(thread) Running: vzctl exec #{ctid} 'mkdir /root/.ssh'"
        mkdir = `vzctl exec #{ctid} 'mkdir /root/.ssh'`
        @log.debug "run_instance(thread) Running: vzctl exec #{ctid} 'chmod 700 /root/.ssh'"
        chmod1 = `vzctl exec #{ctid} 'chmod 700 /root/.ssh'`
        @log.debug "run_instance(thread) Running: vzctl exec #{ctid} 'echo \"#{pubkey}\" >> /root/.ssh/authorized_keys'"
        key = `vzctl exec #{ctid} 'echo "#{pubkey}" >> /root/.ssh/authorized_keys'`
        @log.debug "run_instance(thread) Running: vzctl exec #{ctid} 'chmod 600 /root/.ssh/authorized_keys'"
        chmod2 = `vzctl exec #{ctid} 'chmod 600 /root/.ssh/authorized_keys'`
        # Do the resolver 
        host_resolvers = `cat /etc/resolv.conf`
        @log.debug "run_instance(thread) Running: vzctl exec #{ctid} 'echo \"#{host_resolvers}\" > /etc/resolv.conf'"  
        do_resolvers = `vzctl exec #{ctid} 'echo "#{host_resolvers}" >> /etc/resolv.conf'`
        # We've finished
        @log.debug "run_instance(thread) Finised creating CTID #{ctid} is now up!"
        # Remove the IP that we were using from the array
        @log.debug "run_instance(thread) Removing IP #{ip} from the reserve store"
        $ip_store.delete(IPAddr.new(ip, Socket::AF_INET).to_i)
        @log.debug "run_instance(thread) Removing CTID #{ctid} from the reserve store"
        $ctid_store.delete(ctid)
      end
      
      # Give the user back the details
      @log.debug "run_instance() Returning CTID: #{ctid}, IP: #{ip}"
      return {:id => ctid, :ip => ip}
    end
    
    def destroy_instance(id)
      @log.info "Destroying instance " + id
      @log.debug "destroy_instance() Destroying CTID: " + id
      # Check instance exists
      if ! get_instances('all' => true).detect {|f| f[:id].to_i == id.to_i }
        @log.debug "destroy_instance() CTID #{id} not found"
        raise "Instance ID not found"
      end
      
      @log.debug "destroy_instance() Threading deletion"
      t1 = Thread.new do
        @log.debug "destroy_instance(thread) Running: vzctl stop #{id}"
        `vzctl stop #{id}`
        @log.debug "destroy_instance(thread) Running: vzctl destroy #{id}"
        `vzctl destroy #{id}`
        @log.debug "destroy_instance(thread) Finished destroying CTID #{id}!"
      end
      
      return true
    end    
    
    private
    
    def find_ctid()
      the_ctid = 500
      used_ctids = Array.new
      @log.debug "find_ctid() Starting CTID is " + the_ctid.to_s
      # Fill array with currently used container IDs
      inst = get_instances('all' => true)
      inst.each do |c|
        @log.debug "find_ctid() Found existing CTID for " + c[:id] 
        used_ctids.push(c[:id].to_i)
      end
      
      $ctid_store.each do |c|
        @log.debug "find_ctid() Pushing and CTIDs in the reserve store to used_ctids"
        used_ctids.push(c)
      end
      
      # Sort the array
      @log.debug "find_ctid() Sorting the CTIDs"
      used_ctids.sort!
      used_ctids.each do |c|
        @log.debug "find_ctid() Testing proposed CTID " + the_ctid.to_s + " against " + c.to_s
        if the_ctid == c
          @log.debug "find_ctid() !Container collision found: " + the_ctid.to_s + " = " + c.to_s + ". Incrementing the proposed CTID"
          the_ctid = the_ctid + 1
        end
      end
      
      # Don't have a max to check against. Maybe in the future...
      @log.info "Free CTID found: " + the_ctid.to_s
      return the_ctid
      
    end
    
    def find_ip()
      # Always attempt the lowest IP
      the_ip = IPAddr.new(@ip_start, Socket::AF_INET).to_i
      used_ips = Array.new
      @log.debug "find_ip() Starting IP is " + @ip_start + " (" + the_ip.to_s + ")" 
      # Fill an array with currently used IP addresses in int format
      inst = get_instances('all' => true)
      inst.each do |i|
        @log.debug "find_ip() Found IP " + i[:ip] +" on instance " + i[:id] 
        # Check for "-"
        begin 
          used_ips.push(IPAddr.new(i[:ip], Socket::AF_INET).to_i)
        rescue ArgumentError
          @log.debug "find_ip() IP " + i[:ip] + " is not valid, skipping"
        end
      end
      
      # Push any stored IPs onto the array as well, probably an easier way to push
      $ip_store.each do |i|
        "find_ip() Pushing any IPs in the reserve store to the used_ips array. Stops race conditions"
        used_ips.push(i)
      end
      
      # Sort the array from lowest to highest
      used_ips.sort!
      used_ips.each do |ip|
        @log.debug "find_ip() Testing IP " + the_ip.to_s + " against " + ip.to_s
        # If we get a collision, increment the proposed IP
        if ip == the_ip
          @log.debug "find_ip() !Collided with " + ip.to_s + ". Incrementing the proposed IP"
          the_ip = the_ip + 1
        end
      end
      # Check if the proposed IP is greater than the max
      if the_ip > IPAddr.new(@ip_end, Socket::AF_INET).to_i
        @log.debug "find_ip() No more free leases, the proposed IP is higher than the max!"
        raise 'Do not have any more free leases!'
      else
        # Convert back to dotted notation
        the_ip = IPAddr.new(the_ip, Socket::AF_INET).to_s
        @log.info "Found free IP: " + the_ip
        return the_ip
      end
    end
    



  end
end
