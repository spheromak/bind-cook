
if node.recipes.include?("bind::root")
  default[:dns][:root_zones] = [ "z" ]
end

