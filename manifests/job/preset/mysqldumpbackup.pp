# This preset has the following params
#
# +instance+: name of instance.  will be added as argument to
#   mysqldumpbackup unless it is default.
# +ignore_not_running+: if true, exit silently without taking backup
#   if mysql is not running.
#
# The rest will be stored in configuration file
# (/etc/default/mysqldumpbackup or /etc/default/mysqldumpbackup-$instance)
#
# +keep_backup+: how many days to keep backup
# +backupdir+: where to store backups (file resource must be managed separately)
# +server+: server name to connect to (default is local socket)
# +initscript+: to check if service is running
# +servicename+: to check if service is running
# +my_cnf+: path to my.cnf
# +skip_databases+: array of databases to skip
# +dumpoptions+: extra options to mysqldump
# +compress_program+: default is gzip
# +log_method+: where to log.  default is "console" (ie., stderr)
# +syslog_facility+: where to log.  default is 'daemon'
# +environment+: array of extra environment variables (example: ["HOME=/root"])
#
define bareos::job::preset::mysqldumpbackup(
  $client_name,
  $jobdef,
  $fileset,
  $sched,
  $order,
  $params,
)
{
  if ($jobdef == '') {
    $_jobdef = 'DefaultMySQLJob'
  } else {
    $_jobdef = $jobdef
  }

  ensure_resource('file', '/usr/local/sbin/mysqldumpbackup', {
    source => 'puppet:///modules/bareos/preset/mysqldumpbackup',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  })

  if $params['ignore_not_running'] {
    $options = '-c -r'
  } else {
    $options = '-c'
  }
  if $params['instance'] {
    $instance = "mysqldumpbackup-${params['instance']}"
    $command = "/usr/local/sbin/mysqldumpbackup ${options} ${instance}"
  } else {
    $instance = 'mysqldumpbackup'
    $command = "/usr/local/sbin/mysqldumpbackup ${options}"
  }

  if (count(keys($params)) > 0) {
    ensure_resource('file', "/etc/default/${instance}", {
      content => template('bareos/preset/mysqldumpbackup.conf.erb'),
      mode    => '0400',
      owner   => 'root',
      group   => 'root',
    })
  }

  @@bareos::job_definition {
    $title:
      client_name => $client_name,
      name_suffix => $bareos::client::name_suffix,
      jobdef      => $_jobdef,
      fileset     => $fileset,
      runscript   => [ { 'command' => $command } ],
      sched       => $sched,
      order       => $order,
      tag         => "bareos::server::${bareos::director}"
  }
}

  
