# This preset has the following params
#
# +xtrabackup_package+: name of package containing xtrabackup(1)
# Default: "percona-xtrabackup".
# +mycnf+: location of my.cnf to use
# +skip_binlog+: do not include binlogs in backup. Default: false
#
# If jobdef is set, it is assumed that it will refer to a fileset
# which uses the correct plugin, or that a correct fileset is given
# explicitly.
#
# If neither jobdef nor fileset is set, make a minimal fileset which
# only contains data from the plugin.
#
define bareos::job::preset::percona(
  $short_title,
  $client_name,
  $base,
  $jobdef,
  $fileset,
  $runscript,
  $sched,
  $accurate, # ignored, hardcoded to false
  $order,
  $params,
)
{
  validate_re($bareos::client::implementation, 'bareos')

  if $bareos::client::python_plugin_package {
    ensure_packages($bareos::client::python_plugin_package)
  } else {
    fail("No support yet for ${::operatingsystem}")
  }
  if $bareos::client::python_mysql_package {
    ensure_packages($bareos::client::python_mysql_package)
  }
  if $params['xtrabackup_package'] {
    ensure_packages($params['xtrabackup_package'])
  } else {
    ensure_packages('percona-xtrabackup')
  }


  if $params['skip_binlog'] {
    $include_paths = []
  } else {
    ensure_resource('file', '/etc/bareos/mysql-logbin-location', {
      source => 'puppet:///modules/bareos/preset/percona/mysql-logbin-location',
      mode   => '0555',
      owner  => 'root',
      group  => 'root',
      })
    $include_paths = ['\|/etc/bareos/mysql-logbin-location']
  }

  if ($jobdef == '') {
    $_jobdef = $bareos::default_jobdef
    if $fileset == '' {
      $_fileset = "${bareos::client::client_name}-${short_title}"
      ensure_resource('bareos::client::fileset', $short_title, {
        'fileset_name'  => $_fileset,
        'include_paths' => $include_paths,
        'plugins'       => [ template('bareos/preset/percona-plugin.erb') ],
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
      base        => $base,
      jobdef      => $_jobdef,
      fileset     => $_fileset,
      runscript   => $runscript,
      sched       => $sched,
      accurate    => false,
      order       => $order,
      tag         => "bareos::server::${bareos::director}"
  }
}
