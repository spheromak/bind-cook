#
# Author:: Jesse Nelson <spheromak@gmail.com>
# Cookbook:: Bind
# Recipe:: master
#
#  Recipe that builds up a  master for one of the datacnters
#
include_recipe 'bind::common'

# for now hardcode type
type = "master"

#
# Find dhcp servers.
# Set them up to allow updates
#
dhcp_servers=[]
dhcp_allow = nil

# Find dhcp servers and their ip adress
dhcp_allow = Discovery.all("dhcp_server",
  :node => node,
  :empty_ok => true,
  :environment_aware => true
).map { |n| n.ipaddress }


#
# setup named.conf
#
build_named_conf(
  :query_allow => "any;",
  :recursion => "yes",
  :includes => node[:dns][:zones]
)

#
# gonna collect all rndc_keys here
# we write out rndc.conf after this loop of domains
#
keys = {}
resource = {}
delegates = {}
node[:dns][:zones].each do |zone|
  Chef::Log.info "Setting up DNS Zone: #{zone}"
  bag = data_bag_item("dns_zones", Helpers::DataBags.escape_bagname(zone))

  # make sure we have all the data we need
  validate_zone_data(type, bag)

  # clobber merge keys
  if bag.has_key?("keys")
    keys = Chef::Mixin::DeepMerge.merge(keys, bag["keys"])
  end

  # crate the zone record
  build_zone(zone, type, bag, dhcp_allow)

  #
  # Create the Base Zone File
  # this should only be created ever once
  # after that its all dynamic updates
  #
  template "/var/named/#{type}/db/#{zone}" do
    action :create_if_missing
    source "db.erb"
    owner bind_user
    group bind_group
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
  resources = build_resources(bag["resource_records"], bag["zone_name"])

  # build delegate list
  delegates =  load_delegates(bag)


  # generate nsupdate file
  template "/var/named/#{type}/rr/#{zone}" do
    source "nsupdate.erb"
    owner bind_user
    group bind_group
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
build_keys_conf(keys)
