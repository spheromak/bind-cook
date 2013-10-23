#
# Bind cook common stuff
#

#bring in our dns mixins
class Chef::Recipe
  include Helpers::Dns
  include Helpers::Dns::Resources
end

class Chef::Resource::Template
  include Helpers::Dns
end

class Chef::Resource::Directory
  include Helpers::Dns
end

class Chef::Resource::File
  include Helpers::Dns
end

# ensure all the normal bind stuff is there
include_recipe 'bind::default'

# dangerous, but w/e
# nuke the slaves directory if its there (by default on rhat)
directory "/var/named/slaves" do
  recursive true
  action :delete
end

directory "/var/named" do
  owner bind_user
  group bind_group
  mode 0755
end

directory "/var/named/data" do
  owner bind_user
  group bind_group
  mode 0755
end

# if we have a /etc/bind (ubu deb etc) then link it to /etc/named.conf
link "/etc/named" do
  to "/etc/bind"
  only_if do platform_family?("debian") end
end

# build up the various dirs where we house things
%w/zones master slave/.each do |type|
  %w/db rr/.each do |record|
    directory "/var/named/#{type}" do
      owner bind_user
      group bind_group
      recursive true
      mode  0755
    end

    directory "/var/named/#{type}/#{record}" do
      owner bind_user
      group bind_group
      recursive true
      mode  0755
      not_if do type.eql?("zones") end
    end
  end
end

# setup logs
["/var/log/named-auth.info", "/var/log/update-debug.log"].each do |log|
  file log do
    owner bind_user
    group bind_group
    mode  0660
  end

end

%w{ /etc/named.rfc1912.zones /var/named/named.ca }.each do |cook_file|
  cookbook_file cook_file do
    owner bind_user
    group bind_group
    mode 0664
  end
end

logrotate_app "named_auth" do
  path ["/var/log/named-auth.info", "/var/log/update-debug.log"]
  frequency "daily"
  rotate 3
end
