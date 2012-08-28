module Helpers
  module Dns
    module Resources

      # 
      #  build a zone file
      #  NOTE: this could bea definition, but meh.
      #  NOTE: you could redefine the same zone before as a slave and master, now it will blow up if you try that 
      def build_zone(zone, type, bag, updates=nil)
        update_string = ""
        if updates and updates.class == Array
          updates.each {|i| update_string  << "#{i}; " }
        elsif updates
          update_string  << "#{updates}; "
        end
 
        if bag["allow_update"].class == Array 
          bag["allow_update"].each {|i| update_string << "#{i}; " }
        else 
          update_string <<  "#{bag["allow_update"]}; "
        end
      
        template "/var/named/zones/#{zone}" do
          source "zone.erb"
          owner bind_user
          group bind_group
          mode  0640
          variables(
            :name => zone,
            :allow_query  => bag["allow_query"]  || "none;",
            :allow_update => update_string || "none;",
            :bag => bag,
            :type => type
          )
          notifies :reload, "service[bind9]"
        end
      end

      # common abstract to build resources
      def build_named_conf(args)
        template "/etc/named.conf" do
          source "named.conf.erb"
          owner "root"
          group bind_group
          mode 0640
          variables( args )
          notifies :reload, "service[bind9]"
        end
      end

      def build_keys_conf(keys="")
        template "/etc/named/keys.conf" do
          owner "root"
          group bind_group
          mode 0640
          variables(:keys => keys )
          notifies :reload, "service[bind9]"
        end

        template "/etc/rndc.conf" do
          owner "root"
          group bind_group
          mode 0640
          variables(:keys => keys )
          notifies :reload, "service[bind9]"
        end
      end
    end
  end
end
