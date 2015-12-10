# This preset has the following params
#
# +instance+: name of configuration instance
#
# The rest will be stored in configuration file
# (/etc/mylvmbackup.conf or /etc/mylvmbackup-$instance.conf)
#
# We wrap this in a define bareos::job::preset::mylvmbackup::config to
# do validation and defaults of parameters.  Available parameters are
# documented there.
#
define bareos::job::preset::mylvmbackup(
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

  $base_command = 'env HOME=/root /usr/bin/mylvmbackup --quiet'
  if $params['instance'] {
    $conffile = "/etc/mylvmbackup-${params['instance']}.conf"
    $command = "${base_command} -c ${conffile}"
    $conf_params = delete($params, 'instance')
  } else {
    $conffile = '/etc/mylvmbackup.conf'
    $command = $base_command
    $conf_params = $params
  }

  ensure_resource('bareos::job::preset::mylvmbackup::config', $conffile, $conf_params)
  ensure_packages(['mylvmbackup'])

  @@bareos::job_definition {
    $title:
      client_name => $client_name,
      name_suffix => $bareos::client::name_suffix,
      jobdef      => $_jobdef,
      fileset     => $fileset,
      runscript   => [ { 'command' => "${command} --action=purge" },
                       { 'command' => "${command}", "abortjobonerror" => true },
                     ],
      sched       => $sched,
      order       => $order,
      tag         => "bareos::server::${bareos::director}"
  }
}

  
