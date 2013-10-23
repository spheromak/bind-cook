
default[:dns][:forwarders] = []
default[:dns][:zones] = []
default[:dns][:bag_name] = "dns_zones"

# default self to master (to be overriden in env or role)
default[:dns][:master] = node[:ipaddress]

if platform_family?("debian")
  default[:bind][:group] = "bind"
  default[:bind][:package] = "bind9"
  default[:bind][:package_utils] = "bind9utils"
  default[:bind][:service_name] = "bind9"
elsif platform_family?("rhel")
  default[:bind][:group] = "named"
  default[:bind][:package] = "bind"
  default[:bind][:package_utils] = "bind-utils"
  default[:bind][:service_name] = "named"
end
