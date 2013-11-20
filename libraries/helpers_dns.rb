# Encoding: utf-8
module Helpers
  # Dns container for recipe helpers
  module Dns
    class << self
      include Chef::DSL::DataQuery

      attr_accessor :node

      def bool_to_str(str)
        str ? 'yes' : 'no'
      end

      # Takes anything that can be split or key expanded, or a string.
      #
      # Retruns a properly formated string of bind MATCH_LIST type
      #  i.e. "foo; bar; baz;"
      #
      def match_list(obj)
        list = ''
        if obj.respond_to? :join
          list = obj.join '; '
        elsif obj.respond_to? :split
          list = match_list(obj.split "\s")
        elsif obj.respond_to? :keys
          list = match_list(obj.keys.map { |k| k.to_s })
        else
          fail ArgumentError, 'match_list only knows how to dea with things that respond to: join, split, keys'
        end
        list.strip!
        list += ';' unless list =~ /.*;$/ || list.empty?
        list
      end

      # returns an array of entries suitable for bind zone
      # TODO: Need to refactor this in a big way
      # TODO: TTL should be per-entry IMO
      # TODO: fix cane ABC complexity:
      # libraries/helpers_dns.rb  Helpers::Dns#build_resources  28
      # rubocop:disable all
      def build_resources(data, zone, ttl = '3600')
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
            if data[rr].key?('delete_first') &&
              data[rr]['delete_first'].nil? == false &&
              data[rr]['delete_first'].to_s.downcase == 'true'

              delete_first = true
            end

            if data[rr].key?('delete')
              resources << "delete #{host}"
            end

            #
            # unroll each type and gen the entries
            #
            data[rr].each do |type, val|

              # crete entries suitable for nsupdate
              # TODO: refactor
              case type
              when /ptr/i
                ptr << "delete  #{host}  #{type.upcase} "  if delete_first
                # well ignore everything else if we run into ptr records
                ptr  <<  "add #{host} #{ttl} #{type.upcase}  #{val}"

              when 'A', 'a'
                resources << "delete  #{host}  #{type.upcase} "  if delete_first
                resources << "add #{host} #{ttl} #{type.upcase}  #{val}"

              when /TXT/i
                resources << "delete  #{host} #{type.upcase} "  if delete_first
                if val.class == Array
                  strings = ''
                  val.each { |field| strings << " \"#{field}\" " }
                  resources << "add #{host} #{ttl} TXT  #{strings}"
                else
                  resources << "add #{host} #{ttl} #{type.upcase}  \" #{val} \" "
                end

              when /CNAME/i
                if val.class == Array
                  val.each do |cname|
                    cname = "#{cname}.#{zone}." unless cname =~ /\.$/
                    resources << "delete #{cname}   CNAME" if delete_first
                    resources << "add #{cname} #{ttl} CNAME #{host}"

                  end
                else
                  val = "#{val}.#{zone}." unless val =~ /\.$/
                  resources << "delete #{val} CNAME #{host}" if delete_first
                  resources << "add #{val} #{ttl} CNAME #{host}"
                end
              end
              # end type case

            end
          end
        end

        return resources if ptr.empty?
        ptr
      end
      # rubucop:enable all

      #
      # Takes a bag looks for delegate key.
      # returns array of bags that match those
      #
      def load_delegates(bag)
        delegates = []
        if bag.key?('delegate')
          bag['delegate'].each do |zone|
            delegates << data_bag_item(:dns_zones, data_bag_fqdn(zone))
          end
        end
        delegates
      end

      #
      # all the keys we consider ok in a zone data struct
      #
      def valid_fields
        keys = %w/ ttl refresh retry expire minimum
                   zone_name
                   authority
                   email
                   name_servers
                   master_address
                   allow_query
                   zone_name
          /

        keys << 'allow_update' if type =~ /master/i
        keys
      end

      #
      # do some checks on a data structure
      # to ensure we have them in this bag
      def validate_zone_data(type, data)
        valid_fields.each do |key|
          unless data.key?(key)
            error = "Couldn't find required config option '#{key}' "
            error << "in zone #{data["zone_name"]}"
            fail Chef::Exceptions::AttributeNotFound error
          end

          if data[key].empty?
            error = "Config option #{key} is empty, "
            error << "and should have a value in zone #{data["zone_name"]}"
            fail Chef::Exceptions::AttributeNotFound error
          end
        end
      end

      #
      # Find dhcp servers.
      # Set them up to allow updates
      #
      def find_dhcp_servers
        dhcp_servers = node[:dns][:dhcp_servers] || []

        # Find dhcp servers and their ip adress
        unless node[:dns][:dhcp_servers].empty?
          dhcp_servers = Discovery.all('dhcp_server',
                                       node: node,
                                       empty_ok: true,
                                       environment_aware: true
          ).map { |n| n.ipaddress }
        end

        dhcp_servers
      end

      #
      # determine if node is a master
      #
      def zone_master?(zone)
        have_ip? master
      end

      #
      # does this node have this ipaddr
      #
      def have_ip?(addr)
        node[:network][:interfaces].map do |i, data|
          data['addresses'].map { |ip, crap| ip == addr }
        end.flatten.include? true
      end

      #
      # return ip of master server from the node data or from zone data
      #
      def master(zone = {})
        zone.fetch 'master_address', node[:dns][:master]
      end

      #
      # Pull a zone from bag
      #
      def bag_zone(zone)
        data_bag_item(node[:dns][:bag_name], Helpers::DataBags.escape_bagname(zone))
      end

      #
      # Pull zone from attributes
      #
      def attr_zone(zone)
        node[:dns][:zone_data].fetch zone
      end

      #
      # Load zone from attrib or bag
      #
      def hybrid_zone(zone)
        if node[:dns][:zone_data].key? zone
          attr_zone zone
        else
          bag_zone zone
        end
      end

      #
      # pull zone data from attribs or bags
      #
      def fetch_zone(zone)
        case node[:dns][:zone_strategy]
        when 'hybrid'
          zone_data = hybrid_zone zone
        when 'bags'
          zone_data = bag_zone zone
        else
          zone_data = attr_zone zone
        end
        zone_data
      end
    end
  end
end
