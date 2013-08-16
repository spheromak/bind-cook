
default[:dns][:forwarders] = [ ]
default[:dns][:zones] = [ ]
default[:dns][:bag_name] = "dns_zones"

# default self to master (to be overriden in env or role)
default[:dns][:master] = ipaddress


default[:bind][:group]   = "bind"
default[:bind][:package] = "bind9"
default[:bind][:package_utils] = "bind9utils"
default[:bind][:service_name]  = "bind9"

if platform_family == "rhel"
  default[:bind][:group] = "named"
  default[:bind][:service_name] = "named"

  if platform_version.to_i > 5
    default[:bind][:package] = "bind"
    default[:bind][:package_utils] = "bindutils"
  end
end
