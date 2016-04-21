define bareos::client::job(
  $job_name = '',
  $client_name = $bareos::client::client_name,
  $jobdef = '',
  $runscript = [],
  $fileset = '',
  $sched = '', # "schedule" is a metaparameter, hence reserved
  $schedule_set = 'normal',
  $order = 'N50',
  $preset = '',
  $preset_params = {},
)
{
  validate_array($runscript)
  validate_re($order, '^[A-Z][0-9][0-9]$')

  if $job_name != '' {
    $_job_name = $job_name
    $job_title = $job_name
  } else {
    $_job_name = "${client_name}-${title}${bareos::client::job_suffix}"
    if $client_name == $::fqdn {
      $job_title = $_job_name
    } else {
      $job_title = "${::fqdn}/${_job_name}"
    }
  }
  validate_re($_job_name, '^[A-Za-z0-9.:_-]+$')

  if $sched != '' {
    $_sched = $sched
  } else {
    validate_hash($bareos::schedules)
    $set = $bareos::schedules[$schedule_set]
    validate_array($set)
    $random_index = seeded_rand(65537, $_job_name) % count($set)
    $_sched = $set[$random_index]
  }

  if has_key($bareos::client::filesets, $fileset) {
    if has_key($bareos::client::filesets[$fileset], 'fileset_name') {
      $_fileset = $bareos::client::filesets[$fileset]['fileset_name']
    } else {
      # allow shorthand names, use client_name hint from fileset
      # definition to qualify it
      if has_key($bareos::client::filesets[$fileset], 'client_name') {
        $_fileset = "${bareos::client::filesets[$fileset]['client_name']}-${fileset}"
      } else {
        # $client_name can be different from what fileset uses
        $_fileset = "${bareos::client::client_name}-${fileset}"
      }
    }
  } else {
    $_fileset = $fileset
  }

  if ($preset != '') {
    $preset_def = {
      "${job_title}" => {
        'client_name' => $client_name,
        'jobdef'      => $jobdef,
        'fileset'     => $_fileset,
        'sched'       => $_sched,
        'order'       => $order,
        'runscript'   => $runscript,
        'params'      => $preset_params,
      }
    }
    create_resources($preset, $preset_def)
  } else {
    if ($jobdef == '') {
      $_jobdef = $bareos::default_jobdef
    } else {
      $_jobdef = $jobdef
    }
    
    @@bareos::job_definition {
      $job_title:
        client_name => $client_name,
        name_suffix => $bareos::client::name_suffix,
        jobdef      => $_jobdef,
        fileset     => $_fileset,
        runscript   => $runscript,
        sched       => $_sched,
        order       => $order,
        tag         => "bareos::server::${bareos::director}"
    }
  }
}
