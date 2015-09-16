# Class: bareos::params::client
#
# This class installs a backup client, and exports a definition to be
# used by the backup server.
#
class bareos::params::client {
  $implementation = hiera('bareos::client::implementation', 'bacula')
  $service        = "${implementation}-fd"
  $config_file    = "/etc/${implementation}/${implementation}-fd.conf"
  $log_dir        = "/var/log/${implementation}"
  $schedules      = { 'normal' => ['Friday', 'Saturday', 'Sunday'] }
  $name_suffix    = '-fd'

  case $::osfamily {
    'RedHat': {
      $package     = "${implementation}-client"
      $working_dir = "/var/spool/${implementation}"
      $pid_dir     = '/var/run'
    }
    'Debian': {
      $package     = "${implementation}-fd"
      $working_dir = "/var/lib/${implementation}"
      $pid_dir     = "/var/run/${implementation}"
    }
    default: {
      $package = undef
    }
  }

}
