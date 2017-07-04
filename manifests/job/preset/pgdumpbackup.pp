# This preset has the following params
#
# +instance+: name of instance.  will be added as argument to
#   pgdumpbackup unless it is default.
# +ignore_not_running+: if true, exit silently without taking backup
#   if postgresql is not running.
#
# The other preset parameters are stored in a configuration file
# (/etc/default/pgdumpbackup or /etc/default/pgdumpbackup-$instance)
#
# This is managed by bareos::job::preset::pgdumpbackup::config to
# do validation and defaults of parameters.  Available parameters are
# documented there.
#
define bareos::job::preset::pgdumpbackup(
  $client_name,
  $base,
  $jobdef,
  $fileset,
  $runscript,
  $sched,
  $accurate,
  $order,
  $params,
)
{
  if ($jobdef == '') {
    $_jobdef = 'DefaultPgSQLJob'
  } else {
    $_jobdef = $jobdef
  }

  ensure_resource('file', '/usr/local/sbin/pgdumpbackup', {
    source => 'puppet:///modules/bareos/preset/pgdumpbackup',
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
    $instance = "pgdumpbackup-${params['instance']}"
    $command = "/usr/local/sbin/pgdumpbackup ${options} ${instance}"
  } else {
    $instance = 'pgdumpbackup'
    $command = "/usr/local/sbin/pgdumpbackup ${options}"
  }

  ensure_resource('bareos::job::preset::pgdumpbackup::config',
                  $instance,
                  delete($params, ['instance', 'ignore_not_running']))

  @@bareos::job_definition {
    $title:
      client_name => $client_name,
      name_suffix => $bareos::client::name_suffix,
      base        => $base,
      jobdef      => $_jobdef,
      fileset     => $fileset,
      runscript   => flatten([$runscript, [{ 'command' => $command }] ]),
      sched       => $sched,
      accurate    => $accurate,
      order       => $order,
      tag         => "bareos::server::${bareos::director}"
  }
}
