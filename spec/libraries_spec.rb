require 'chefspec'

# describe 'test_cook_skeleton::default' do
#  let(:chef_run) { ChefSpec::ChefRunner.new.converge 'test_cook_skeleton::default' }
#  it 'does something' do
#    pending 'Your recipe examples go here.'
#  end
# end

require_relative '../libraries/helpers_dns'
describe 'Helpers::Dns.match_list' do
  before do
    @matched =  'one; two; three;'
  end

  it 'handles Arrays' do
    Helpers::Dns.match_list(%w/one two three/).should eq @matched
  end

  it 'handles Strings' do
    Helpers::Dns.match_list(' one two three ').should eq @matched
    Helpers::Dns.match_list('  one two three').should eq @matched
    Helpers::Dns.match_list('one  two three  ').should eq @matched
  end

  it 'handles Hashes' do
    Helpers::Dns.match_list(one: '1', two: '2', three: '3').should eq @matched
  end

  it 'handles empty strings' do
    Helpers::Dns.match_list('').should eq ''
  end
end
