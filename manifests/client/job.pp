define bareos::client::job(
  $job_name = '',
  $client_name = $bareos::client::client_name,
  $jobdef = '',
  $fileset = '',
  $runscript = [],
  $sched = '', # "schedule" is a metaparameter, hence reserved
  $schedule_set = 'normal',
  $base_job_name = '',
  $make_base_job = false,
  $base_schedule = 'base', # explicit schedule name if $sched is set, otherwise a set name
  $base_jobdef = '',
  $accurate = '',
  $order = 'N50',
  $preset = '',
  $preset_params = {},
)
{
  validate_array($runscript)
  validate_re($order, '^[A-Z][0-9][0-9]$')
  validate_bool($make_base_job)

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

  if $preset != '' and $make_base_job {
    fail("${title}: make_base_job can not (currently) be combined with a preset")
  }

  if $sched != '' {
    $_sched = $sched
    $_base_sched = $base_schedule
  } else {
    validate_hash($bareos::schedules)
    $set = $bareos::schedules[$schedule_set]
    validate_array($set)
    $random_index = seeded_rand(65537, $_job_name) % count($set)
    $_sched = $set[$random_index]
    if $make_base_job {
      if ! has_key($bareos::schedules, $base_schedule) {
        fail("Can not find ${base_schedule} in bareos::schedules")
      }
      $base_set = $bareos::schedules[$base_schedule]
      validate_array($base_set)
      if count($base_set) != count($set) {
        fail("Number of entries in schedule sets ${schedule_set} and ${base_schedule} must be equal")
      }
      $_base_sched = $base_set[$random_index]
    }
  }

  if $make_base_job {
    $_base_job_name = $base_job_name ? {
      ''      => "${job_title}-base",
      default => $base_job_name,
    }
    $_base_jobdef = $base_jobdef ? {
      ''      => $bareos::default_base_jobdef,
      default => $base_jobdef
    }
  } else {
    $_base_job_name = $base_job_name
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
    $_preset = $preset ? { /::/ => $preset, default => "bareos::job::preset::${preset}" }
    $preset_def = {
      "${job_title}" => {
        'client_name' => $client_name,
        'jobdef'      => $jobdef,
        'fileset'     => $_fileset,
        'runscript'   => $runscript,
        'sched'       => $_sched,
        'accurate'    => $accurate,
        'order'       => $order,
        'params'      => $preset_params,
      }
    }
    create_resources($_preset, $preset_def)
  } else {
    $_jobdef = $jobdef ? {
      ''      => $bareos::default_jobdef,
      default => $jobdef
    }

    @@bareos::job_definition {
      $job_title:
        client_name => $client_name,
        name_suffix => $bareos::client::name_suffix,
        jobdef      => $_jobdef,
        base        => $_base_job_name,
        fileset     => $_fileset,
        runscript   => $runscript,
        sched       => $_sched,
        accurate    => $accurate,
        order       => $order,
        tag         => "bareos::server::${bareos::director}"
    }

    if $make_base_job {
      @@bareos::job_definition {
        $_base_job_name:
          client_name => $client_name,
          name_suffix => $bareos::client::name_suffix,
          jobdef      => $_base_jobdef,
          fileset     => $_fileset,
          runscript   => $runscript,
          sched       => $_base_sched,
          accurate    => $accurate,
          order       => $order,
          tag         => "bareos::server::${bareos::director}"
      }
    }
  }
}
