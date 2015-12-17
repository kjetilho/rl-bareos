# This class is included by preset classes to create parent directory
# when the preset manages a sub-directory.
#
class bareos::client::backup_dir {
  if $bareos::client::manage_backup_dir {
    file { $bareos::client::backup_dir:
      ensure => directory,
      owner  => $bareos::client::backup_dir_owner,
      group  => $bareos::client::backup_dir_group,
      mode   => $bareos::client::backup_dir_mode;
    }
  }
}
