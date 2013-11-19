# Encoding: utf-8
#
#  This recipe should store host data back into a "node_data" bag
#


# setup bag_item based on fqdn

class Chef::Recipe
  include Helpers::Bags
end

# data = { :run_list =>  node.run_list }

# save_bag_item(data_bag_fqdn("hostdata_#{node.domain}"), data_bag_fqdn, data)
