source 'https://rubygems.org'

# Testing requires Ruby 2.0.  Ruby 2.1 is recommended,
# since Puppet 3.8 doesn't support 2.2 very well.
group :test do
  gem 'rake'
  gem 'puppet', ENV['PUPPET_VERSION'] || '~> 3.0'
  gem 'facter', '~> 2.4.0'
  gem 'json'
  gem 'json_pure'
  gem 'rspec-puppet', '= 2.5.0' # see rspec-puppet issue 620.  2.6.0 breaks exported_resources
  gem 'puppetlabs_spec_helper'
  gem 'rspec-puppet-facts'
end
