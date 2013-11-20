# Encoding: utf-8
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
#

include_recipe 'apparmor' if platform_family?('debian')

package node[:bind][:package] do
  action :install
end

package node[:bind][:package_utils] do
  action :install
end

directory node[:bind][:conf_dir]

file node[:bind][:conf_file] do
  owner 'root'
  group node[:bind][:group]
  mode 0640
end

template "#{node[:bind][:conf_dir]}/named.conf.options" do
  source 'named.conf.options.erb'
  variables(
    forwarders: node[:dns][:forwarders]
  )
  mode 0644
  owner 'root'
  group node[:bind][:group]
  notifies :restart, "service[#{node[:bind][:service_name]}]"
end

service node[:bind][:service_name] do
  supports restart: true, status: true, reload: true
  action :enable
end
