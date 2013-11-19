# Encoding: utf-8
# Author:: Jesse Nelson (<spheromak@gmail.com>)
# Cookbook Name:: bind
# Provider:: zone
#
# Copyright 2013, Jesse Nelson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
use_inline_resources

def whyrun_supported?
  true
end

action :create do
  service node[:bind][:service_name] do
    action :nothing
  end

  updates = ''
  if new_resource.zone_data.key? 'allow_update'
    updates = Helpers::Dns.match_list(new_resource.zone_data['allow_update'])
  end
  updates << Helpers::Dns.match_list(new_resource.allow_update)

  template "/var/named/zones/#{new_resource.name}" do
    source 'zone.erb'
    owner node[:bind][:user]
    group node[:bind][:group]
    mode  0640
    variables(
      name: new_resource.name,
      allow_query: Helpers::Dns.match_list(new_resource.allow_query),
      allow_update: updates,
      bag: new_resource.zone_data,
      type: new_resource.zone_type
    )
    notifies :reload, "service[#{node[:bind][:service_name]}]"
  end
end
