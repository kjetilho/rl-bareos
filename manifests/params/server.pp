class bareos::params::server {
  case $::operatingsystem {
    'Ubuntu', 'CentOS', 'RedHat', 'AlmaLinux', 'Rocky': {
      $packages = [
        'bareos-database-postgresql',
        'bareos-storage-tape',
        'bareos-storage',
      ]
    }
    default: {
      fail("${::operatingsystem} is not supported yet")
    }
  }
}
