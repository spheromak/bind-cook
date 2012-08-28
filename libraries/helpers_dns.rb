module Helpers
  module Dns

    # unrolls zone resource_record data from databags
    # returns an array of entries suitable for bind zone
    # TODO: Need to refactor this in a big way
    # TODO: TTL should be per-entry IMO
    def build_resources(data, zone, ttl="3600")
      ptr = []
      resources = [] 
      # unroll resource_records and pass in lists for the template
      unless data.nil? or data.empty?
        data.each_key do |rr|

          host = rr
          # find out if this host is qualified entry or not
          # ends in .   \.$  
          # or is a litteral @ 
          unless host =~ /\.$|@/
            host = "#{host}.#{zone}."
          end 

          delete_first = nil
          # see if we want to remove records before adding          
          if data[rr].has_key?("delete_first") and 
          data[rr]["delete_first"].nil? == false and 
          data[rr]["delete_first"].to_s.downcase == "true"

            delete_first = true  
          end 
         
          if data[rr].has_key?("delete") 
            resources << "delete #{host}" 
          end 

          #
          # unroll each type and gen the entries
          #
          data[rr].each do |type,value|
            
            # crete entries suitable for nsupdate 
            case type
            when /ptr/i 
              ptr << "delete  #{host}  #{type.upcase} "  if delete_first 
              # well ignore everything else if we run into ptr records
              ptr  <<  "add #{host} #{ttl} #{type.upcase}  #{value}"

            when "A","a"
              resources << "delete  #{host}  #{type.upcase} "  if delete_first 
              resources << "add #{host} #{ttl} #{type.upcase}  #{value}"

            when /TXT/i
              resources << "delete  #{host} #{type.upcase} "  if delete_first 
              if value.class == Array 
                strings = ""
                value.each {|field| strings << " \"#{field}\" "  }
                resources << "add #{host} #{ttl} TXT  #{strings}" 
              else
                resources << "add #{host} #{ttl} #{type.upcase}  \" #{value} \" "
              end

            when /CNAME/i
              if value.class == Array
                value.each do |cname| 
                  cname = "#{cname}.#{zone}." unless cname =~ /\.$/
                  resources << "delete #{cname}   CNAME" if delete_first
                  resources << "add #{cname} #{ttl} CNAME #{host}"
              
                end
              else
                value = "#{value}.#{zone}." unless value =~ /\.$/
                resources << "delete #{value} CNAME #{host}" if delete_first
                resources << "add #{value} #{ttl} CNAME #{host}"
              end
            end
            # end type case 
            
          end
        end
      end

      return resources if ptr.empty?
      return ptr
    end

  
    #   
    # search all nodes in this domain
    #  and collect some info into a TXT record
    # expects a resource_record hash from domain data bag
    def collect_txt(records)
      # now were gonna do some inventory collection
      search( :node, "domain:#{node.domain}").each do |n|
        # pull out facts to insert into TXT
        # we could do cnames for now just merge txt
        
        # these are the facts we are inserting 
        texts = [ "Run_list: #{n.run_list}", "Environment: #{n.chef_environment}" ]

        # merge this data with existing records.
        if records.has_key?(n.hostname)
          if records[n.hostname].has_key?("TXT")
            Chef::Log.debug "#{records[n.hostname]["TXT"]}"
            records[n.hostname]["TXT"]  << texts
            # gotta fold our array push into a 1dim array
            records[n.hostname]["TXT"].flatten!
          else
            records[n.hostname]["TXT"] =  texts
          end
        else
          records[n.hostname] = { "TXT" => texts }
        end
        Chef::Log.debug "#{records[n.hostname]["TXT"]}"
      end
      records
    end
    
    #
    # resolve the right group for bind based on platform
    #
    def bind_group
      # figure whitch group name to use
      case node[:platform]
      when "ubuntu","debian" 
        bind_group = "bind"
      else
        bind_group = "named"
      end
    end
    alias :bind_user :bind_group

    # 
    # Takes a bag looks for delegate key. 
    # returns array of bags that match those
    #
    def load_delegates(bag)
      delegates = []
      if bag.has_key?("delegate") 
        bag["delegate"].each do |zone|
          delegates << data_bag_item(:dns_zones, data_bag_fqdn(zone) )
        end
      end
      delegates  
    end

    def node_dns_master?(bag)
      master = false
      # NOTE: verry brittle /
      %/eth0 eth1 bond0 bond1 ib0 ib1/.each do |int|
        if node[:network].has_key?("ipaddress_#{int}")
          if node[:network]["ipaddress_#{int}"] == bag["master_address"]
            master = true 
          end
        end 
      end
      master
    end

    #
    # do some checks on a data structure 
    # to ensure we have them in this bag
    #
    def validate_zone_data(type, data)
      keys=%w/ ttl refresh retry expire minimum
        zone_name 
        authority 
        email 
        name_servers
        master_address
        allow_query
        zone_name
        /

      case type
      when /slave/i
      when /master/i
        keys << "allow_update"
      end
 
      keys.each do |key|
        unless data.has_key?(key)
          raise Chef::Exceptions::AttributeNotFound,
            "Couldn't find required config option '#{key}' in zone #{data["zone_name"]}"           
        end
        
        if data[key].empty?
          raise Chef::Exceptions::AttributeNotFound,
            "Config option #{key} is empty, and should have a value in zone #{data["zone_name"]}"  
        end
      end
    end

  end
end
