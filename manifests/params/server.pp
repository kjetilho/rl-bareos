class bareos::params::server {
  case $::operatingsystem {
    'Ubuntu': {
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
