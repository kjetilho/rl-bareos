# This preset has the following params
#
# +instance+: name of instance.  will be added as argument to
#   mysqldumpbackup unless it is default.
# +ignore_not_running+: if true, exit silently without taking backup
#   if mysql is not running.
#
# The other preset parameters are stored in a configuration file
# (/etc/default/mysqldumpbackup or /etc/default/mysqldumpbackup-$instance)
#
# This is managed by bareos::job::preset::mysqldumpbackup::config to
# do validation and defaults of parameters.  Available parameters are
# documented there.
#
define bareos::job::preset::mysqldumpbackup(
  $client_name,
  $jobdef,
  $fileset,
  $sched,
  $order,
  $runscript,
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

  ensure_resource('bareos::job::preset::mysqldumpbackup::config',
                  $instance,
                  delete($params, ['instance', 'ignore_not_running']))

  @@bareos::job_definition {
    $title:
      client_name => $client_name,
      name_suffix => $bareos::client::name_suffix,
      jobdef      => $_jobdef,
      fileset     => $fileset,
      runscript   => flatten([$runscript, [{ 'command' => $command }] ]),
      sched       => $sched,
      order       => $order,
      tag         => "bareos::server::${bareos::director}"
  }
}

  
