# Class: bareos::client
#
# This class installs a backup client, and exports a definition to be
# used by the backup server.
#
# password:
# Set this parameter to get the same password on several clients.
# This is not the actual password used in the configuration files, for
# that we hash it with ${bareos::secret}.  We do that extra step to
# avoid putting the actual password in PuppetDB.
# 
#
class bareos::client (
  $implementation = $bareos::params::client::implementation,
  $client_name    = "${::fqdn}-fd",
  $address        = $::fqdn,
  $password       = $::fqdn,
  $job_retention  = '180d',
  $file_retention = '60d',
  $concurrency    = 10,
  $service_ensure = 'running',
  $monitors       = {},
  $jobs           = {},
  $schedules      = $bareos::params::client::schedules,
  # the remainder are unlikely to need changing
  $package        = $bareos::params::client::package,
  $config_file    = $bareos::params::client::config_file,
  $service        = $bareos::params::client::service,
  $log_dir        = $bareos::params::client::log_dir,
  $log_file       = $bareos::params::client::log_file,
  $pid_dir        = $bareos::params::client::pid_dir,
  $working_dir    = $bareos::params::client::working_dir,
) inherits bareos::params::client
{

  include bareos

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    require => Package[$package],
    before  => Service[$service],
  }

  ensure_packages($package)
  # package { $package: ensure => present }

  service { $service: }

  # Allow value of undef or '' to not manage the "ensure" parameter
  if $service_ensure {
    Service[$service] {
      ensure => $service_ensure
    }
  }

  file { $config_file:
    ensure  => file,
    content => template('bareos/client/bareos-fd.conf.erb'),
    notify  => Service[$service]
  }

  file { $log_dir:
    ensure => directory,
  }

  @@bareos::client_definition { $client_name:
    password       => $password,
    address        => $address,
    job_retention  => $job_retention,
    file_retention => $file_retention,
    concurrency    => $concurrency,
    tag            => "bareos::server::${bareos::director}",
  }

  if ! empty($jobs) {
    Bareos::Job_definition {
      tag => "bareos::server::${bareos::director}"
    }
    create_resources('@@bareos::job_definition', $jobs)
  }
}
