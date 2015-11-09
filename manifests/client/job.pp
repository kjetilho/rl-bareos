define bareos::client::job(
  $job_name = '',
  $jobdef = '',
  $runscript = [],
  $fileset = '',
  $sched = '', # "schedule" is a metaparameter, hence reserved
  $schedule_set = 'normal',
  $preset = '',
  $preset_params = {},
)
{
  validate_array($runscript)

  if $job_name {
    $_job_name = $job_name
  } else {
    $_job_name = "${bareos::client::client_name}-${title}"
  }
  if $sched {
    $_sched = $sched
  } else {
    validate_hash($bareos::schedules)
    $set = $bareos::schedules[$schedule_set]
    validate_array($set)
    $random_index = fqdn_rand(65537, $title) % count($set)
    $_sched = $set[$random_index]
  }

  if ($preset != '') {
    $preset_def = {
      "${_job_name}" => {
        'jobdef'  => $jobdef,
        'fileset' => $fileset,
        'sched'   => $_sched,
        'params'  => $preset_params,
      }
    }
    create_resources($preset, $preset_def)
  } else {
    if ($jobdef == '') {
      $_jobdef = 'DefaultJob'
    } else {
      $_jobdef = $jobdef
    }
    
    @@bareos::job_definition {
      $_job_name:
        client_name => $bareos::client::client_name,
        name_suffix => $bareos::client::name_suffix,
        jobdef      => $_jobdef,
        fileset     => $fileset,
        runscript   => $runscript,
        sched       => $_sched,
        tag         => "bareos::server::${bareos::director}"
    }
  }
}
