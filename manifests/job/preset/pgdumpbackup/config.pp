# Define: bareos::job::preset::pgdumpbackup::config
#
# Do not call directly.
#
# +keep_backup+: how many days to keep backup
# +backup_dir+: where to store backups
# +backup_dir_owner+: what permissions to use on backup_dir.  Default: 'root'
# +backup_dir_group+: what permissions to use on backup_dir.  Default: 'root'
# +backup_dir_mode+: what permissions to use on backup_dir.  Default: '0750'
# +server+: server name to connect to (default is local socket)
# +initscript+: to check if service is running
# +cluster+: what cluster to dump (default "", which means connect to port 5432)
# +skip_databases+: array of databases to skip
# +log_method+: where to log.  default is "console" (ie., stderr)
# +syslog_facility+: where to log.  default is 'daemon'
# +environ+: array of extra environment variables (example: ["HOME=/root"])
#
define bareos::job::preset::pgdumpbackup::config(
  $keep_backup=3,
  $backup_dir="${bareos::client::backup_dir}/postgresql",
  $backup_dir_owner=$bareos::client::backup_dir_owner,
  $backup_dir_group=$bareos::client::backup_dir_group,
  $backup_dir_mode='0750',
  $server='',
  $initscript='',
  $cluster='',
  $skip_databases=[],
  $log_method='console',
  $syslog_facility='daemon',
  $environ=[],
)
{
  validate_array($environ)
  validate_array($skip_databases)

  if dirname($backup_dir) == $bareos::client::backup_dir {
    include bareos::client::backup_dir
  }

  if ! defined (File[$backup_dir]) {
    file { $backup_dir:
      ensure => directory,
      owner  => $backup_dir_owner,
      group  => $backup_dir_group,
      mode   => $backup_dir_mode,
    }
  }

  file { "/etc/default/${title}":
    content => template('bareos/preset/pgdumpbackup.conf.erb'),
    mode    => '0400',
    owner   => 'root',
    group   => 'root',
  }
}
