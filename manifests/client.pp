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
class bareos::client(
  $ensure         = 'present',
  $implementation = $bareos::params::client::implementation,
  $client_name    = $::fqdn,
  $name_suffix    = $bareos::params::client::name_suffix,
  $job_suffix     = $bareos::params::client::job_suffix,
  $address        = $::fqdn,
  $password       = $::fqdn,
  $service_addr   = {},
  $passive        = false,
  $client_initiated_connection = false,
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
  $systemd_limits    = {},
  $ipv6              = $bareos::params::client::ipv6,
  $tls_enable        = '',
  # the remainder are unlikely to need changing
  $port              = $bareos::params::client::port,
  $root_user         = $bareos::params::client::root_user,
  $root_group        = $bareos::params::client::root_group,
  $package           = $bareos::params::client::package,
  $competitor        = $bareos::params::client::competitor,
  $python_plugin_package = $bareos::params::client::python_plugin_package,
  $config_file       = $bareos::params::client::config_file,
  $service           = $bareos::params::client::service,
  $service_ensure    = 'running',
  $service_enable    = true,
  $log_dir           = $bareos::params::client::log_dir,
  $pid_dir           = $bareos::params::client::pid_dir,
  $working_dir       = $bareos::params::client::working_dir,
  $plugin_dir        = $bareos::params::client::plugin_dir,
) inherits bareos::params::client
{
  include bareos

  File {
    owner   => $root_user,
    group   => $root_group,
    mode    => '0440',
    require => Package[$package],
    before  => Service[$service],
  }

  validate_re($implementation, '^(bareos|bacula)$')
  validate_re($job_retention, '^[0-9]+d$')
  validate_re($file_retention, '^[0-9]+d$')
  validate_re($client_name, '^[A-Za-z0-9.-]+$')
  validate_re($ensure, '^(present|absent)$')
  validate_hash($monitors)
  validate_hash($jobs)
  validate_absolute_path($config_file)
  if $::osfamily != 'windows' {
    validate_absolute_path($log_dir)
    validate_absolute_path($pid_dir)
    validate_absolute_path($working_dir)
  }
  validate_hash($systemd_limits)

  if $implementation == 'bacula' {
    if $passive {
      notify { 'bacula-passive':
        message => 'Bacula does not support passive mode'
      }
    }
    if $client_initiated_connection {
      notify { 'bacula-client-initiated':
        message => 'Bacula does not support client initiated connection'
      }
    }
  }

  if $ensure == 'absent' {
    include bareos::client::uninstall
  }
  else {
    include bareos::client::install
  }
}
