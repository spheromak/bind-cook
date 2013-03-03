
default[:dns][:forwarders] = [ ]
default[:dns][:zones] = [ ]
default[:dns][:bag_name] = "dns_zones"

# default self to master (to be overriden in env or role)
default[:dns][:master] = ipaddress
