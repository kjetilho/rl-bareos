# This preset has one param
#
# +xtrapackage_package+: name of package containing xtrabackup(1)
# Default is "percona-xtrabackup".
#
# If jobdef is set, it is assumed that it will refer to a fileset
# which uses the correct plugin, or that a correct fileset is given
# explicitly.
#
# If neither jobdef nor fileset is set, make a minimal fileset which
# only contains data from the plugin.
#
define bareos::job::preset::percona(
  $client_name,
  $jobdef,
  $fileset,
  $sched,
  $order,
  $runscript,
  $params,
)
{
  validate_re($bareos::client::implementation, 'bareos')

  if $bareos::client::python_plugin_package {
    ensure_packages($bareos::client::python_plugin_package)
  } else {
    fail("No support yet for ${::operatingsystem}")
  }
  if $params['xtrabackup_package'] {
    ensure_packages($params['xtrabackup_package'])
  } else {
    ensure_packages('percona-xtrabackup')
  }

  if ($jobdef == '') {
    $_jobdef = $bareos::default_jobdef
    if $fileset == '' {
      $_fileset = "${bareos::client::client_name}-percona"
      ensure_resource('bareos::client::fileset', 'percona', {
        'fileset_name' => $_fileset,
        'include_paths' => [],
        'sparse'  => false,
        'plugins' => ["python:module_path=${bareos::client::plugin_dir}:module_name=bareos-fd-percona"],
      })
    } else {
      $_fileset = $fileset
    }
  } else {
    $_jobdef = $jobdef
  }

  ensure_resource('file', "${bareos::client::plugin_dir}/bareos-fd-percona.py", {
    source => 'puppet:///modules/bareos/preset/percona/bareos-fd-percona.py',
    mode   => '0555',
    owner  => 'root',
    group  => 'root',
    notify => Service[$bareos::client::service]
  })
  ensure_resource('file', "${bareos::client::plugin_dir}/BareosFdPercona.py", {
    source => 'puppet:///modules/bareos/preset/percona/BareosFdPercona.py',
    mode   => '0555',
    owner  => 'root',
    group  => 'root',
    notify => Service[$bareos::client::service]
  })


  @@bareos::job_definition {
    $title:
      client_name => $client_name,
      name_suffix => $bareos::client::name_suffix,
      jobdef      => $_jobdef,
      fileset     => $_fileset,
      runscript   => $runscript,
      sched       => $sched,
      order       => $order,
      tag         => "bareos::server::${bareos::director}"
  }
}
