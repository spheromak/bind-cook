#
# Author:: Jesse Nelson <spheromak@gmail.com>
# Cookbook:: Bind
# Recipe:: server
#
#  Recipe that builds up a  master for one of the datacnters
#

include_recipe 'bind::default'
include_recipe 'bind::common'


if node[:dns][:master] == node[:ipaddress]
  type = "master"
  dhcp_allow = Helpers::Dns.find_dhcp_servers(node)
else
  type = "slave"
end

bind_conf "server" do
  zones node[:dns][:zones]
end

#
# gonna collect all rndc_keys here
keys = node[:dns][:keys] || {}
resource = {}
delegates = {}
node[:dns][:zones].each do |zone|
  puts "ZONE: #{zone} "
  log "Setting up DNS Zone: #{zone}"
  bag = data_bag_item("dns_zones", Helpers::DataBags.escape_bagname(zone))

  # make sure we have all the data we need
  Helpers::Dns.validate_zone_data(type, bag)

  # clobber merge keys
  if bag.has_key?("keys")
    keys = Chef::Mixin::DeepMerge.merge(keys, bag["keys"])
  end

  # crate the zone record
  bind_zone zone do
    zone_type type
    zone_data bag
    allow_query "any"
    allow_update dhcp_allow
  end

  #
  # Create the Base Zone File
  # this should only be created ever once
  # after that its all dynamic updates
  #
  template "/var/named/#{type}/db/#{zone}" do
    action :create_if_missing
    source "db.erb"
    owner node[:bind][:user]
    group node[:bind][:group]
    mode  0640
    variables(:name => zone, :data => bag)
    notifies :restart, "service[#{node[:bind][:service_name]}]"
  end


  #
  #
  # setup the nsupdate exec for this zone
  # resources below will exec it
  #
  execute "nsupdate_#{zone}" do
    action :nothing
    #
    # due to a bug in nsupdate it will always assert even when it succeds
    # we need to grep and us returns 1  to ensure our grep oens't match (fail condition)
    # nsupdate bug: http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=622084
    #command "nsupdate -v /var/named/#{type}/rr/#{zone}  2>&1 | grep 'update failed:' "
    # returns 1
    opts = ""
    case node[:platform_family]
    when "rhel"
      opts = "-v"
    when "debian"
      opts = "-lv"
    end

    command "nsupdate #{opts} /var/named/#{type}/rr/#{zone}"
  end

  # collect txt record info from searchs on this domain
  # parse the resource_records in this zone and get the formated entries
  #  for now disable txt records so dhcp can update
  #resources = build_resources(collect_txt(bag["resource_records"]), bag["zone_name"])
  resources = Helpers::Dns.build_resources(bag["resource_records"], bag["zone_name"])

  # build delegate list
  delegates =  Helpers::Dns.load_delegates(bag)


  # generate nsupdate file
  template "/var/named/#{type}/rr/#{zone}" do
    source "nsupdate.erb"
    owner node[:bind][:user]
    group node[:bind][:group]
    mode  0640
    variables(
      :zone => bag["zone_name"],
      :records =>  resources,
      # set the ttl for delegates
      :ttl => "172800",
      :delegates => delegates
    )
    notifies :run, "execute[nsupdate_#{zone}]", :delayed
  end
end

# build out rndc
node.run_state[:dns_keys] = keys
include_recipe "bind::_keys"
