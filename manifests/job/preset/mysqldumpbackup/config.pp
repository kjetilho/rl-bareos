# Define: bareos::job::preset::mysqldumpbackup::config
#
# Do not call directly.
#
# +keep_backup+: how many days to keep backup
# +backup_dir+: where to store backups
# +backup_dir_owner+: what permissions to use on backup_dir.  Default: 'root'
# +backup_dir_group+: what permissions to use on backup_dir.  Default: 'root'
# +backup_dir_mode+: what permissions to use on backup_dir.  Default: '0750'
# +server+: server name to connect to (default is localhost)
# +socket+: socket name to connect to, overrides server (default is unset)
# +initscript+: to check if service is running
# +servicename+: to check if service is running
# +my_cnf+: path to my.cnf
# +skip_databases+: array of databases to skip
# +dumpoptions+: extra options to mysqldump
# +compress_program+: default is gzip
# +log_method+: where to log.  default is "console" (ie., stderr)
# +syslog_facility+: where to log.  default is 'daemon'
# +environ+: array of extra environment variables (example: ["HOME=/root"])
#
define bareos::job::preset::mysqldumpbackup::config(
  $keep_backup=3,
  $backupdir='', # 
  $backup_dir="${bareos::client::backup_dir}/mysql",
  $backup_dir_owner=$bareos::client::backup_dir_owner,
  $backup_dir_group=$bareos::client::backup_dir_group,
  $backup_dir_mode='0750',
  $server='',
  $socket='',
  $initscript='',
  $servicename='',
  $my_cnf='',
  $skip_databases=[],
  $dumpoptions='',
  $compress_program='',
  $log_method='console',
  $syslog_facility='daemon',
  $environ=[],
)
{
  validate_array($environ)
  validate_array($skip_databases)

  # temporary code for backwards compatibility
  if ($backupdir != '') {
    $_backup_dir = $backupdir
  } else {
    $_backup_dir = $backup_dir
  }
  if dirname($_backup_dir) == $bareos::client::backup_dir {
    include bareos::client::backup_dir
  }
  if ! defined (File[$_backup_dir]) {
    file { $_backup_dir:
      ensure => directory,
      owner  => $backup_dir_owner,
      group  => $backup_dir_group,
      mode   => $backup_dir_mode,
    }
  }
  
  file { "/etc/default/${title}":
    content => template('bareos/preset/mysqldumpbackup.conf.erb'),
    mode    => '0400',
    owner   => 'root',
    group   => 'root',
  }
}
