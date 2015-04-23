# Class: bareos::params::client
#
# This class installs a backup client, and exports a definition to be
# used by the backup server.
#
class bareos::params::client {
  $service_ensure = 'running'
  $service        = 'bacula-fd'
  $config_file    = '/etc/bacula/bacula-fd.conf'
  $directors      = {}
  $hostname       = $::fqdn

  case $::osfamily {
    'RedHat': {
      $package = 'bacula-client'
    }
    'Debian': {
      $package = 'bacula-fd'
    }
    default: {
      $package = undef
    }
  }

}
