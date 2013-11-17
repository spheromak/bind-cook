require 'chefspec'

describe 'bind::server' do
  let(:chef_run) { ChefSpec::Runner.new( platform: 'centos', version: '6.4', step_into: ['bind_conf']).converge(described_recipe) }

  it 'sets up named.conf via lwrp' do
    expect(chef_run).to render_file('/etc/named.conf')
  end

  it 'sets up /var/named/zones/#{zone} via lwrp' do
    expect(chef_run).to render_file('/etc/named.conf')
  end
end
