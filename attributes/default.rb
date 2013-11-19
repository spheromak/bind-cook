# Encoding: utf-8
# <> array of forwarder
default[:dns][:forwarders] = []

# <> array of zones this should use
default[:dns][:zones] = []

# <> hybrid, attribute, bags controlls where to pull zone data from. hybrid preferes attributes over bags.
default[:dns][:zone_strategy] = 'hybrid'

# <> data for each zone, when not using bags for zones this hash is refrenced
default[:dns][:zone_data] = {}

# <> bag to look at for zones
default[:dns][:bag_name] = 'dns_zones'

# <> global master dns server
default[:dns][:master] = node[:ipaddress]

# <> list of dhcp servers to be added to the allow_updates these should be ipaddresses
default[:dns][:dhcp_servers] = []

# <> where to drop the keys.conf
default[:bind][:key_file] = '/etc/named/keys.conf'

default[:bind][:conf_file] = '/etc/named.conf'
default[:bind][:conf_dir]  = '/etc/named'
# <> platform options
if platform_family?('debian')
  default[:bind][:user]      = 'bind'
  default[:bind][:group]     = 'bind'
  default[:bind][:package]   = 'bind9'
  default[:bind][:conf_file] = '/etc/bind/named.conf'
  default[:bind][:conf_dir]  = '/etc/bind'
  default[:bind][:service_name]  = 'bind9'
  default[:bind][:package_utils] = 'bind9utils'
elsif platform_family?('rhel')
  default[:bind][:user]    = 'named'
  default[:bind][:group]   = 'named'
  default[:bind][:package] = 'bind'
  default[:bind][:service_name]  = 'named'
  default[:bind][:package_utils] = 'bind-utils'
 default[:bind][:conf_dir]  = '/etc'
end
