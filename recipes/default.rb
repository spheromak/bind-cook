#
# Author:: Jesse Nelson <spheromak@gmail.com>
#
# based on the bind cookbook included in the dell crowbar project:
# http://github.com/dellcloudedge/crowbar 
#
# Copyright 2012, Jesse Nelson 
# Copyright 2011, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# bring in helpers for "is_yum_platform" method
include_recipe "helpers"

case node[:platform]
when "ubuntu","debian" 
  bind_group = "bind"
when "centos","redhat","xenserver","amazon" 
  bind_group = "named"
end

package "bind9" do
  package_name "bind" if is_yum_platform
  action :install
end

package "bind9utils" do
  package_name "bind-utils" if is_yum_platform
  action :install
end

directory "/etc/bind"

file "/etc/named.conf" do
  owner "root"
  group bind_group
  mode 0640
end
  
template "/etc/bind/named.conf.options" do
  source "named.conf.options.erb"
  variables(:forwarders => node[:dns][:forwarders])
  mode 0644
  owner "root"
  group bind_group
  notifies :restart, "service[bind9]"
end

service "bind9" do
  service_name "named" if is_yum_platform
  supports :restart => true, :status => true, :reload => true
  running true
  enabled true
  action :enable
end


