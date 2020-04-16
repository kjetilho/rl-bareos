class bareos::client::install
inherits bareos::client
{
  # lint:ignore:variable_scope We refer to inherited variables

  File {
    owner   => $root_user,
    group   => $root_group,
    mode    => '0440',
    require => Package[$package],
    before  => Service[$service],
  }

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
    Service[$service] { ensure => $service_ensure }
  }

  file { $config_file:
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
    passive        => $passive,
    client_initiated_connection => $client_initiated_connection,
    port           => $port,
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
  # lint:endignore
}
