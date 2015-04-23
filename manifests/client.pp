# Class: bareos::client
#
# This class installs a backup client, and exports a definition to be
# used by the backup server.
#
class bareos::client (
  $hostname       = $bareos::params::client::hostname,
  $package        = $bareos::params::client::package,
  $config_file    = $bareos::params::client::config_file,
  $service        = $bareos::params::client::service,
  $service_ensure = $bareos::params::client::service_ensure,
  $directors      = $bareos::params::client::directors,

) inherits bareos::params::client {

  include bareos

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    require => Package[$package],
    notify  => Service[$service],
  }

  ensure_packages($package)

  service{ $service:
    ensure => 'running',
  }

  file { $config_file:
    ensure  => file,
    content => template('bareos/client/bacula-fd.conf.erb'),
  }

  file { '/var/log/bacula':
    ensure => directory,
  }
}
