# Define: bareos::job_definition
#
# This define installs a configuration file on the backup server.
#
define bareos::job_definition(
  $client_name,
  $name_suffix,
  $jobdef,
  $fileset,
  $sched,
  $runscript,
)
{
  $job_name = regsubst($title, '.*?\/', '')
  $filename = "${bareos::server::job_file_prefix}${job_name}.conf"

  ensure_resource('file', $filename, {
    content => template('bareos/server/job.erb'),
    owner   => 'root',
    group   => 'bareos',
    mode    => '0444',
  })

  if $fileset != '' {
    File[$filename] {
      require => Bareos::Fileset_definition[$fileset]
    }
  }
}
