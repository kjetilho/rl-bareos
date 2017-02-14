# This preset has no params (yet)
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
  if ($jobdef == '') {
    $_jobdef = 'DefaultMySQLJob'
  } else {
    $_jobdef = $jobdef
  }

  if $bareos::client::python_plugin_package {
    ensure_packages($bareos::client::python_plugin_package)
  }
  if $fileset != '' {
    ensure_resource('bareos::client::fileset', {
      'percona':
        include_paths => [],
        sparse  => false,
        plugins => ["python:module_path=${bareos::client::plugin_dir}:module_name=bareos-fd-percona"]
    }
    $_fileset = 'percona'
  } else {
    $_fileset = $fileset
  }

  @@bareos::job_definition {
    $title:
      client_name => $client_name,
      name_suffix => $bareos::client::name_suffix,
      jobdef      => $_jobdef,
      fileset     => $_fileset,
      sched       => $sched,
      order       => $order,
      tag         => "bareos::server::${bareos::director}"
  }
}
