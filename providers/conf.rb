#
# Author:: Jesse Nelson (<spheromak@gmail.com>)
# Cookbook Name:: bind
# Provider:: conf
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
  template new_resource.config_file do
    cookbook new_resource.cookbook
    source "named.conf.erb"
    owner "root"
    group bind_group
    mode 0640
    variables(
      allow_query: Helpers::Dns.match_list(new_resource.allow_query),
      recursion: Helpers::Dns.bool_to_str(new_resource.recursion),
      zones: new_resource.zones
    )
    notifies :reload, "service[#{node[:bind][:service_name]}]"
  end
end
