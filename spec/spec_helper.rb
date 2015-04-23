require 'puppetlabs_spec_helper/module_spec_helper'

# Get facts from a gem
require 'rspec-puppet-facts'
include RspecPuppetFacts

# Default environment for tests
RSpec.configure do |c|
  c.hiera_config = 'spec/fixtures/hiera/hiera.yaml'
  c.default_facts = { fqdn: 'node.example.com' }
end
