require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'

# workaround for https://github.com/rodjek/puppet-lint/issues/331
Rake::Task[:lint].clear

PuppetLint.configuration.relative = true
PuppetLint.configuration.fail_on_warnings = true
%w( 80chars documentation parameter_order 2sp_soft_tabs arrow_alignment ).each do |check|
  PuppetLint.configuration.send("disable_#{check}")
end

exclude_paths = [
  'pkg/**/*',
  'vendor/**/*',
  'spec/**/*',
]
PuppetSyntax.exclude_paths = exclude_paths

PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = exclude_paths
  config.log_format = '%{path}:%{linenumber}:%{check}:%{KIND}:%{message}'
end

desc 'Run syntax, lint, and spec tests.'
task :test => [
  :syntax,
  :lint,
  :spec,
]
