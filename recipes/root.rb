#
# Author:: Jesse Nelson <spheromak@gmail.com>
# Cookbook:: Bind
# Recipe:: dc_master
# 
#  Recipe that builds up a  master for one of the datacnters
#

# ensure all the normal bind stuff is there
include_recipe 'bind::common'

build_named_conf(   
    :query_allow => "any;",
    :recursion => "yes",
    :includes => node[:dns][:root_zones]
  )


keys = {}
node[:dns][:root_zones].each do |zone|

  # call to data_bag_fqdn simply replaces '.' with '-' 
  bag = data_bag_item("dns_zones", data_bag_fqdn(zone) )

  validate_zone_data("master", bag)

  # clobber merge keys 
  if bag.has_key?("keys")
    keys = Chef::Mixin::DeepMerge.merge(keys, bag["keys"] )
  end

  build_zone( zone, "master", bag)

  # 
  # the DB file sets the headers up, 
  #  it's only triggered by resource changes however
  # 
  template "/var/named/master/db/#{zone}" do 
    action :nothing
    source "db.erb"
    owner bind_user
    group bind_group
    mode  0640
    variables( :name => zone, :data => bag )
    notifies :start, "service[bind9]" 
    notifies :reload, "service[bind9]" 
  end

  # parse the resource_records in this zone and get the formated entries
  resources = build_resources( collect_txt(bag["resource_records"]), bag["zone_name"] )
  
  # build delegate list
  delegates = load_delegates(bag)

  template "/var/named/master/rr/#{zone}" do
    source "rr.erb"
    owner bind_user
    group bind_group
    mode  0640
    variables( 
      :records =>  resources,
      :delegates => delegates
    )
    notifies :create, "template[/var/named/master/db/#{zone}]",  :immediately 
  end
end

build_keys_conf(keys)
