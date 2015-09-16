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
    validate_array($bareos::client::schedules[$schedule_set])

    $random_schedule = fqdn_rand(65537, $title)
    $_schedule = template('bareos/schedule_picker.erb')
  }

  @@bareos::job_definition {
    $_job_name:
      client_name => $client_name,
      jobdef      => $jobdef,
      fileset     => $fileset,
      runscript   => $runscript,
      schedule    => $_schedule,
      tag         => "bareos::server::${bareos::director}"
  }
}
