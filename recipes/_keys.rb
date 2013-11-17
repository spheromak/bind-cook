
template "/etc/named/keys.conf" do
  owner "root"
  group node[:bind][:group]
  mode 0640
  variables( keys: node.run_state[:dns_keys] )
  notifies :reload, "service[#{node[:bind][:service_name]}]"
end
