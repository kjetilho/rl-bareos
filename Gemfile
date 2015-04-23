source 'https://rubygems.org'

group :test do
  gem 'rake'
  gem 'puppet', ENV['PUPPET_VERSION'] || '~> 3.7.0'
  gem 'rspec-puppet',
      git: 'https://github.com/ssm/rspec-puppet.git',
      ref: 'feature/rspec3'
  gem 'puppetlabs_spec_helper'
  gem 'rspec-puppet-facts',
      require: false
end

group :development do
  gem 'guard-rake'
end
