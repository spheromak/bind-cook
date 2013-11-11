
default[:dns][:forwarders] = []
default[:dns][:zones] = []
default[:dns][:use_bags] = true
default[:dns][:bag_name] = "dns_zones"

#<> master dns server
default[:dns][:master] = node[:ipaddress]

#<> list of dhcp servers to be added to the allow_updates these should be ipaddresses
default[:dns][:dhcp_servers] = []

#<> platform options
if platform_family?("debian")
  default[:bind][:user] = "bind"
  default[:bind][:group] = "bind"
  default[:bind][:package] = "bind9"
  default[:bind][:package_utils] = "bind9utils"
  default[:bind][:service_name] = "bind9"
elsif platform_family?("rhel")
  default[:bind][:user] = "named"
  default[:bind][:group] = "named"
  default[:bind][:package] = "bind"
  default[:bind][:package_utils] = "bind-utils"
  default[:bind][:service_name] = "named"
end
