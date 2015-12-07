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
  $name_suffix    = '-fd'
  $job_suffix     = '-job'
  # don't worry about Linux specific names for now
  $fstype = [
    'rootfs', 'ext2', 'ext3', 'ext4', 'jfs', 'reiserfs', 'xfs',
  ]

  case $::osfamily {
    'RedHat': {
      $package     = "${implementation}-client"
      $working_dir = "/var/spool/${implementation}"
      $pid_dir     = '/var/run'
    }
    'Debian': {
      case $implementation {
        'bacula': {
          $package = "${implementation}-fd"
        }
        'bareos': {
          $package = "${implementation}-filedaemon"
        }
      }
      $working_dir = "/var/lib/${implementation}"
      $pid_dir     = "/var/run/${implementation}"
    }
    default: {
      $package     = undef
      $working_dir = "/var/spool/${implementation}"
      $pid_dir     = '/var/run'
    }
  }
}
