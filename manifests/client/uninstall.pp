class bareos::client::uninstall
inherits bareos::client
{
  # lint:ignore:variable_scope We refer to inherited variables
  ensure_packages($package, { ensure => absent })
  if $competitor {
    ensure_packages($competitor, { ensure => absent })
    Package[$competitor] -> Package[$package]
  }

  service { $service:
    ensure => stopped,
    enable => false,
  }

  file { $config_file:
    ensure  => absent,
  }

  if $log_dir {
    file { $log_dir:
      ensure  => absent,
      recurse => true,
      force   => true,
    }
  }

  if ! empty($systemd_limits) {
    file {
      "/etc/systemd/system/${service}.service.d":
        ensure  => absent,
        recurse => true,
        force   => true,
    }
  }
  # lint:endignore
}
