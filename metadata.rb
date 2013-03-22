name             "bind"
maintainer       "Jesse Nelson"
maintainer_email "spheromak@gmail.com"
description      "Bind Cookbooks driven via DataBags" 
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "2.0.0"

%w{ centos xenserver ubuntu debian }.each do |os|
  supports os
end

depends "ruby-helper"
depends "helpers-databags"
depends "discovery"

depends "logrotate"
depends "apparmor"
