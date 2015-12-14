# bareos::job::preset::mylvmbackup::config
#
# == Mandatory options
# +vgname+: name of volume group
# +lvname+: name of logical volume
#
# == Optional
# +relpath+: relative path to mysql data from mount point of logical volume.  Default: ""
# +lvsize+: reserved size for snapshot.  Default: 256M
# +keep_backup+: how many backup copies to retain.  Default: 3
# +backup_dir+: where to put backups.  Default: '/var/backups/mylvmbackup'
# +backup_dir_owner+: what permissions to use on backup_dir.  Default: 'root'
# +backup_dir_group+: what permissions to use on backup_dir.  Default: 'root'
# +backup_dir_mode+: what permissions to use on backup_dir.  Default: '0750'
# +my_cnf+: location of my.cnf.  Default (in mylvmbackup): '/etc/my.cnf'
# +prefix+: prefix to use in name of backup files.  Default (in mylvmbackup): 'backup'
# +compress_program+: program to use for compression.  Default (in mylvmbackup): 'gzip'
# +log_method+: where to log.  Default: 'console' (stdout/stderr)
# +syslog_facility+: Default: 'daemon'
# +mountdir+: where to mount the snapshot.  Default: '/var/cache/mylvmbackup'
# +local_config+: text appended verbatim to mylvmbackup.conf.
#
define bareos::job::preset::mylvmbackup::config(
  $vgname,
  $lvname,
  $relpath='',
  $lvsize='256M',
  $keep_backup=3,
  $backup_dir="${bareos::client::backup_dir}/mylvmbackup",
  $backup_dir_owner=$bareos::client::backup_dir_owner,
  $backup_dir_group=$bareos::client::backup_dir_group,
  $backup_dir_mode='0750',
  $snapshot_only=false, # TODO
  $my_cnf='',
  $prefix='',
  $compress_program='',
  $log_method='console',
  $syslog_facility='daemon',
  $mountdir='/var/cache/mylvmbackup',
  $local_config='',
)
{
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
  file { $title:
    content => template('bareos/preset/mylvmbackup.conf.erb'),
    mode    => '0400',
    owner   => 'root',
    group   => 'root',
  }
}
