# Encoding: utf-8
#
# Author:: Jesse Nelson <spheromak@gmail.com>
# Cookbook:: Bind
# Recipe:: slave
#
#  Recipe that builds up a  master for one of the datacnters
#

include_recipe 'bind::common'

# for now hardcode type
type = 'slave'

keys = {}
node[:dns][:zones].each do |zone|
  bag = data_bag_item('dns_zones', Helpers::DataBags.escape_bagname(zone))

  # clobber merge keys
  if bag.key?('keys')
    keys = Chef::Mixin::DeepMerge.merge(keys, bag['keys'])
  end

  # do some bag key validation before moving on
  validate_zone_data('slave', bag)
  build_zone(zone, 'slave', bag)
end

build_keys_conf(keys)
