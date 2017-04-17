# Class: bareos::client
#
# This class installs a backup client, and exports a definition to be
# used by the backup server.
#
# +password+:
#   Set this parameter to get the same password on several clients.
#   This is not the actual password used in the configuration files,
#   for that we hash it with ${bareos::secret}.  We do that extra step
#   to avoid putting the actual password in PuppetDB.
# 
#
class bareos::client (
  $implementation = $bareos::params::client::implementation,
  $client_name    = $::fqdn,
  $name_suffix    = $bareos::params::client::name_suffix,
  $job_suffix     = $bareos::params::client::job_suffix,
  $address        = $::fqdn,
  $password       = $::fqdn,
  $service_addr   = {},
  $job_retention  = '180d',
  $file_retention = '60d',
  $concurrency    = 10,
  $monitors       = {},
  $jobs           = {'system' => {}},
  $filesets       = {},
  $compression    = $bareos::params::client::compression,
  $fstype         = $bareos::params::client::fstype,
  $exclude_paths  = $bareos::params::client::exclude_paths,
  $exclude_patterns  = $bareos::params::client::exclude_patterns,
  $manage_backup_dir = true,
  $backup_dir        = $bareos::params::client::backup_dir,
  $backup_dir_owner  = $bareos::params::client::backup_dir_owner,
  $backup_dir_group  = $bareos::params::client::backup_dir_group,
  $backup_dir_mode   = $bareos::params::client::backup_dir_mode,
  # the remainder are unlikely to need changing
  $root_user      = $bareos::params::client::root_user,
  $root_group     = $bareos::params::client::root_group,
  $package        = $bareos::params::client::package,
  $competitor     = $bareos::params::client::competitor,
  $python_plugin_package = $bareos::params::client::python_plugin_package,
  $config_file    = $bareos::params::client::config_file,
  $service        = $bareos::params::client::service,
  $service_ensure = 'running',
  $service_enable = true,
  $log_dir        = $bareos::params::client::log_dir,
  $pid_dir        = $bareos::params::client::pid_dir,
  $working_dir    = $bareos::params::client::working_dir,
  $plugin_dir     = $bareos::params::client::plugin_dir,
  $systemd_limits = {},
) inherits bareos::params::client
{

  include bareos

  File {
    owner   => $root_user,
    group   => $root_group,
    mode    => '0400',
    require => Package[$package],
    before  => Service[$service],
  }

  validate_re($implementation, '^(bareos|bacula)$')
  validate_re($job_retention, '^[0-9]+d$')
  validate_re($file_retention, '^[0-9]+d$')
  validate_re($client_name, '^[A-Za-z0-9.-]+$')
  validate_hash($monitors)
  validate_hash($jobs)
  validate_absolute_path($config_file)
  if $::osfamily != 'windows' {
    validate_absolute_path($log_dir)
    validate_absolute_path($pid_dir)
    validate_absolute_path($working_dir)
  }
  validate_hash($systemd_limits)

  ensure_packages($package)
  if $competitor {
    ensure_packages($competitor, { ensure => absent })
    Package[$competitor] -> Package[$package]
  }

  service {
    $service:
      enable => $service_enable
  }

  # Allow value of undef or '' to not manage the "ensure" parameter
  if $service_ensure {
    Service[$service] {
      ensure => $service_ensure
    }
  }

  file { $config_file:
    ensure  => file,
    content => template('bareos/client/bareos-fd.conf.erb'),
    notify  => Service[$service]
  }

  if $log_dir {
    file { $log_dir:
      ensure => directory,
      owner  => $bareos::client::implementation,
      group  => $bareos::client::implementation,
      mode   => '0755';
    }
  }

  if ! empty($systemd_limits) {
    file {
      "/etc/systemd/system/${service}.service.d":
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755';
      "/etc/systemd/system/${service}.service.d/limits.conf":
        # this should notify Exec['systemctl daemon-reload']
        content => template('bareos/client/systemd/limits.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444';
    }
  }

  @@bareos::client_definition { "${client_name}${name_suffix}":
    password       => $password,
    address        => $address,
    job_retention  => $job_retention,
    file_retention => $file_retention,
    concurrency    => $concurrency,
    security_zone  => $bareos::security_zone,
    tag            => "bareos::server::${bareos::director}",
  }

  if ! empty($service_addr) {
    if (has_key($service_addr, $client_name)) {
      fail("Using client's own name (${client_name}) as a service address does not make sense")
    }
    create_resources('bareos::client::service_addr', $service_addr)
  }
  if ! empty($jobs) {
    create_resources('bareos::client::job', $jobs)
  }
  if ! empty($filesets) {
    create_resources('bareos::client::fileset', $filesets)
  }
}
