# Class: bareos::params::client
#
# This class installs a backup client, and exports a definition to be
# used by the backup server.
#
class bareos::params::client {
  case $::osfamily {
    'windows': {
      $_impl = 'bareos'
      $root_user = 'Administrators'
      $root_group = 'Administrators'
      $fstype = [ 'ntfs' ]
      $exclude_paths = [ 'C:/Windows/Temp' ]
      $exclude_patterns = {}
    }
    default: {
      $_impl = 'bacula'
      $root_user = 'root'
      $root_group = 'root'
      $fstype = [ 'btrfs', 'ext2', 'ext3', 'ext4', 'jfs', 'reiserfs', 'rootfs', 'xfs' ]
      $exclude_paths = [ '/mnt', '/var/cache' ]
      $exclude_patterns = {}
    }
  }
  $implementation = hiera('bareos::client::implementation', $_impl)
  $compression = 'GZIP'
  $port = 9102

  case $::osfamily {
    'windows': {
      $service = 'Bareos-fd'
      $log_dir = false
      # Notice the use of UNC to get an "absolute path", this enables
      # us to run regression tests for Windows code on a Unix system.
      $config_file = "C:/ProgramData/Bareos/${implementation}-fd.conf"
      # See https://bugs.bareos.org/view.php?id=477
      $ipv6 = false
    }
    default: {
      $service = "${implementation}-fd"
      $log_dir = "/var/log/${implementation}"
      $config_file = "/etc/${implementation}/${implementation}-fd.conf"
      $ipv6 = true
    }
  }

  $name_suffix = '-fd'
  $job_suffix  = '-job'

  $backup_dir       = '/var/backups'
  $backup_dir_owner = 'root'
  $backup_dir_group = 'root'
  $backup_dir_mode  = '0755'

  case $::osfamily {
    'RedHat': {
      case $implementation {
        'bareos': {
          $package     = "${implementation}-filedaemon"
          $competitor  = ['bacula-client', 'bacula-common']
          $working_dir = "/var/lib/${implementation}"
          $pid_dir     = $working_dir
          $plugin_dir  = "/usr/lib64/${implementation}/plugins"
          $python_plugin_package = "${implementation}-filedaemon-python-plugin"
        }
        default: {
          $package     = "${implementation}-client"
          $competitor  = ['bareos-filedaemon', 'bareos-common']
          $working_dir = "/var/spool/${implementation}"
          $pid_dir     = '/var/run'
          $plugin_dir  = false
          $python_plugin_package = false
        }
      }
      if versioncmp($::operatingsystemmajrelease, '7.0') <= 0 {
        $python_mysql_package = 'MySQL-python'
      }
      else {
        $python_mysql_package = 'python3-mysql'
      }
    }
    'Debian': {
      $working_dir = "/var/lib/${implementation}"
      case $implementation {
        'bareos': {
          $package    = "${implementation}-filedaemon"
          $competitor = ['bacula-fd', 'bacula-common']
          $pid_dir    = $working_dir
          $plugin_dir = "/usr/lib/${implementation}/plugins"
          $python_plugin_package = "${implementation}-filedaemon-python-plugin"
          $python_mysql_package = 'python-mysqldb'
        }
        default: {
          $package    = "${implementation}-fd"
          $competitor = ['bareos-filedaemon', 'bareos-common']
          $pid_dir    = "/var/run/${implementation}"
          $plugin_dir = false
          $python_plugin_package = false
          $python_mysql_package = 'python-mysqldb'
        }
      }
    }
    'windows': {
      $package     = []
      $competitor  = false
      $pid_dir     = false
      $plugin_dir  = false
      $python_plugin_package = false
      $python_mysql_package = false
      $working_dir = false
    }
    default: {
      $package     = undef
      $working_dir = "/var/spool/${implementation}"
      $pid_dir     = '/var/run'
      $plugin_dir  = false
      $python_plugin_package = false
      $python_mysql_package = false
    }
  }
}
