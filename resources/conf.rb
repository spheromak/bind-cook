# Encoding: utf-8
actions :create
default_action :create

# <> should terminate as a proper bind string
attribute :config_file,
          kind_of: String,
          default: '/etc/named.conf',
          name_attribute: true

attribute :allow_query,
          kind_of: Array,
          default: ['any']

attribute :recursion,
          kind_of: [TrueClass, FalseClass],
          default: true

attribute :zones,
          kind_of: Array

attribute :cookbook,
          kind_of: String,
          default: 'bind'
