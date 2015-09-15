define bareos::client::job(
  $job_name = '',
  $jobdef = 'DefaultJob',
  $fileset = '',
)
{
  if $job_name {
    $_job_name = $job_name
  } else {
    $_job_name = "${bareos::client::client_name}-${title}"
  }
  @@bareos::job_definition {
    $_job_name:
      client_name => $client_name,
      jobdef      => $jobdef,
      fileset     => $fileset,
      tag         => "bareos::server::${bareos::director}"
  }
}
