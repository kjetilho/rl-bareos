require 'puppetlabs_spec_helper/module_spec_helper'

# Get facts from a gem
require 'rspec-puppet-facts'
include RspecPuppetFacts

# For testing on a subset of supported OS.
# Usage: on_os({ :kernel => Linux }).each do |os, facts| ...
def on_os(filter={})
  matches = []
  on_supported_os.each do |os, facts|
    facts.merge! RSpec.configuration.default_facts
    unless filter.map do |k, v| facts[k] == v; end.include? false
      matches.push [os, facts]
    end
  end
  if matches.empty?
    raise Puppet::Error "No supported OS matching #{filter}"
  end
  matches
end

# Run test just once (on an arbitrarily chosen supported OS), for
# tests without OS specific code.
# Usage: on_one_os.each do |os, facts| ...
def on_one_os(filter={})
  [on_os(filter)[0]]
end

# Default environment for tests
RSpec.configure do |c|
  c.hiera_config = 'spec/fixtures/hiera/hiera.yaml'
  c.default_facts = { :specialcase => 'normal',
                      :fqdn => 'node.example.com',
                    }
end
