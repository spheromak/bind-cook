
template node[:bind][:key_file] do
  owner 'root'
  group node[:bind][:group]
  mode 0640
  variables(keys: node.run_state[:dns_keys])
  notifies :restart, "service[#{node[:bind][:service_name]}]", :immediately
end
