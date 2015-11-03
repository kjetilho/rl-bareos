require 'puppetlabs_spec_helper/module_spec_helper'

# Get facts from a gem
require 'rspec-puppet-facts'
include RspecPuppetFacts

### BEGIN code taken from https://gist.github.com/nhinds/32d4fb95d754d075effb

# require Puppet::Resource::Catalog::Compiler
require 'puppet/indirector/catalog/compiler'

# Magic to add a catalog.exported_resources accessor
class Puppet::Resource::Catalog::Compiler
  alias_method :filter_exclude_exported_resources, :filter
  def filter(catalog)
    filter_exclude_exported_resources(catalog).tap do |filtered|
      # Every time we filter a catalog, add a .exported_resources to it.
      filtered.define_singleton_method(:exported_resources) do
        # The block passed to filter returns `false` if it wants to keep a resource. Go figure.
        catalog.filter { |r| !r.exported? }
      end
    end
  end
end

module Support
  module ExportedResources
    # Get exported resources as a catalog. Compatible with all catalog matchers, e.g.
    # `expect(exported_resources).to contain_myexportedresource('name').with_param('value')`
    def exported_resources
      # Catalog matchers expect something that can receive .call
      proc { subject.call.exported_resources }
    end
  end
end

### END imported code

# Default environment for tests
RSpec.configure do |c|
  c.include Support::ExportedResources # see above
  c.hiera_config = 'spec/fixtures/hiera/hiera.yaml'
  c.default_facts = { fqdn: 'node.example.com' }
end
