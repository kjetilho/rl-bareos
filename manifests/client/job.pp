define bareos::client::job(
  $job_name = '',
  $jobdef = 'DefaultJob',
  $runscript = [],
  $fileset = '',
  $schedule = '',
  $schedule_set = 'normal',
)
{
  validate_array($runscript)

  if $job_name {
    $_job_name = $job_name
  } else {
    $_job_name = "${bareos::client::client_name}-${title}"
  }
  if $schedule {
    $_schedule = $schedule
  } else {
    validate_hash($bareos::client::schedules)
    $set = $bareos::client::schedules[$schedule_set]
    validate_array($set)
    $random_index = fqdn_rand(65537, $title) % count($set)
    $_schedule = $set[$random_index]
  }

  @@bareos::job_definition {
    $_job_name:
      client_name => $bareos::client::client_name,
      name_suffix => $bareos::client::name_suffix,
      jobdef      => $jobdef,
      fileset     => $fileset,
      runscript   => $runscript,
      schedule    => $_schedule,
      tag         => "bareos::server::${bareos::director}"
  }
}
