# This is managed by bareos::job::preset::s3::config to
# do validation and defaults of parameters.
#
# If the job name is on one of the formats
#
#   "anything:user_name"
#   "anything:user_name:bucket"
#   "anything:user_name:bucket:prefix"
#
# ... the appropriate params will be get their default values from it.
# When no bucket is specified, the user name is taken as the default.
#
# Other available parameters are documented in config.pp
#
define bareos::job::preset::s3(
  $client_name,
  $jobdef,
  $fileset,
  $runscript,
  $sched,
  $accurate,
  $order,
  $params,
)
{
  # This preset only works with Bareos
  validate_re($bareos::client::implementation, 'bareos')

  if $fileset != '' {
    fail('bareos::job::preset::s3 does not support specifying a fileset')
  }

  if $bareos::client::python_plugin_package {
    ensure_packages($bareos::client::python_plugin_package)
  } else {
    fail("No support yet for ${::operatingsystem}")
  }

  if ($jobdef == '') {
    $_jobdef = $bareos::default_jobdef
  } else {
    $_jobdef = $jobdef
  }

  ensure_resource('file', '/usr/local/sbin/bareos-make-s3-access', {
    source => 'puppet:///modules/bareos/preset/s3/sbin/bareos-make-s3-access',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  })

  ensure_resource('file', "${bareos::client::plugin_dir}/bareos-fd-s3.py", {
    source => 'puppet:///modules/bareos/preset/s3/bareos-fd-s3.py',
    mode   => '0555',
    owner  => 'root',
    group  => 'root',
    notify => Service[$bareos::client::service]
  })
  ensure_resource('file', "${bareos::client::plugin_dir}/BareosFdPluginS3.py", {
    source => 'puppet:///modules/bareos/preset/s3/BareosFdPluginS3.py',
    mode   => '0555',
    owner  => 'root',
    group  => 'root',
    notify => Service[$bareos::client::service]
  })
  ensure_resource('file', "${bareos::client::plugin_dir}/S3", {
    source  => 'puppet:///modules/bareos/preset/s3/S3',
    ensure  => directory,
    recurse => true,
    mode    => '0555',
    owner   => 'root',
    group   => 'root',
    notify  => Service[$bareos::client::service]
  })

  ensure_resource('file', '/etc/bareos/s3', {
    ensure => 'directory',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  })

  # We make our own fileset name from the job name
  $_fileset = regsubst($title, "(.+/)?${client_name}-(.*)${bareos::client::job_suffix}$", '\2')

  $comps = split($_fileset, ':')
  case size($comps) {
    1: {
      $title_params = {}
    }
    2: {
      # First element is ignored.
      $title_params = {
        user_name => $comps[1],
        bucket    => $comps[1], # same as user name
      }
    }
    default: {
      $title_params = {
        user_name => $comps[1],
        bucket    => $comps[2] ? { '' => $comps[1], default => $comps[2] },
      }
      # components 3 and onwards are ignored as well
    }
  }
  $pass_on = {
    client_name => $client_name,
  }

  ensure_resource('bareos::job::preset::s3::config', $_fileset,
                  merge($title_params, $pass_on, $params))

  @@bareos::job_definition {
    $title:
      client_name => $client_name,
      name_suffix => $bareos::client::name_suffix,
      jobdef      => $_jobdef,
      fileset     => "S3 ${_fileset}",
      runscript   => $runscript,
      sched       => $sched,
      accurate    => $accurate ? { '' => true, default => $accurate },
      order       => $order,
      tag         => "bareos::server::${bareos::director}"
  }
}
