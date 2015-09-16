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
  $log_file       = "${log_dir}/${implementation}-fd.log"
  $working_dir    = "/var/lib/${implementation}"
  $pid_dir        = "/var/run/${implementation}"
  $schedules      = { 'normal' => ['Friday', 'Saturday', 'Sunday'] }
  case $::osfamily {
    'RedHat': {
      $package = "${implementation}-client"
    }
    'Debian': {
      $package = "${implementation}-fd"
    }
    default: {
      $package = undef
    }
  }

}
