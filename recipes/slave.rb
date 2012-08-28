#
# Author:: Jesse Nelson <spheromak@gmail.com>
# Cookbook:: Bind
# Recipe:: slave
# 
#  Recipe that builds up a  master for one of the datacnters
#

include_recipe 'bind::common'

# for now hardcode type
type = "slave"

#
# find zones we should own by looking @ the datacenters bag
#
dc_bag = data_bag_item("datacenters", data_bag_fqdn(node[:domain]) )

# setup named.conf
build_named_conf(   
    :query_allow => "any;",
    :recursion => "yes",
    :includes => dc_bag["zones"]
  )

keys = {}
dc_bag["zones"].each do |zone| 
  bag = data_bag_item("dns_zones", data_bag_fqdn(zone) )
  
  # clobber merge keys 
  if bag.has_key?("keys")
    keys = Chef::Mixin::DeepMerge.merge(keys, bag["keys"] )
  end
 
  # do some bag key validation before moving on
  validate_zone_data("slave", bag)
  build_zone(zone, "slave", bag)   
end

build_keys_conf( keys )
