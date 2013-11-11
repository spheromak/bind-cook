require 'chefspec'

describe 'bind::server' do
  let(:chef_run) { ChefSpec::Runner.new(step_into: ['bind_conf']).converge(described_recipe) }
end
