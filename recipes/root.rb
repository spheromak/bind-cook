# Encoding: utf-8
# Author:: Jesse Nelson <spheromak@gmail.com>
# Cookbook:: Bind
# Recipe:: dc_master
#
#  Recipe that builds up a  master for one of the datacnters
#

# ensure all the normal bind stuff is there
include_recipe 'bind::common'

build_named_conf(
  query_allow: 'any;',
  recursion: 'yes',
  includes: node[:dns][:root_zones]
)

keys = {}
node[:dns][:root_zones].each do |zone|

  bag = data_bag_item('dns_zones', Helpers::DataBags.escape_bagname(zone))

  validate_zone_data('master', bag)

  # clobber merge keys
  keys = Chef::Mixin::DeepMerge.merge(keys, bag['keys']) if bag.key?('keys')

  build_zone(zone, 'master', bag)

  #
  # the DB file sets the headers up,
  #  it's only triggered by resource changes however
  #
  template "/var/named/master/db/#{zone}" do
    action :nothing
    source 'db.erb'
    owner bind_user
    group bind_group
    mode  0640
    variables(name: zone, data: bag)
    notifies :start, "service[#{node[:bind][:service_name]}]"
    notifies :reload, "service[#{node[:bind][:service_name]}]"
  end

  # parse the resource_records in this zone and get the formated entries
  resources = build_resources(collect_txt(bag['resource_records']),
                              bag['zone_name'])

  # build delegate list
  delegates = load_delegates(bag)

  template "/var/named/master/rr/#{zone}" do
    source 'rr.erb'
    owner bind_user
    group bind_group
    mode  0640
    variables(
      records: resources,
      delegates: delegates
    )
    notifies :create, "template[/var/named/master/db/#{zone}]", :immediately
  end
end

build_keys_conf(keys)
